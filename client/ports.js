function init(node, flags) {

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////// GLOBAL VARIABLES FOR THE ACQUISITION PHASE ////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // The stream of the device.
    let stream = null;

    // Whether we are currently trying to detect the devices.
    let detectingDevices = false;

    // Whether we should redetect the devices when we're done because we've received an event stating that it changed.
    let shouldRedetectDevices = false;

    // Wether the camera is currently being bound.
    let bindingDevice = false;

    // What device we should rebind the device because it was changed.
    let shouldRebindDevice = null;

    // Whether the user asked to unbind the camera while it was not unbindable.
    let unbindRequested = false;

    // The recorder we will be using when recording the camera / microphone of the user.
    let recorder = null;

    // The video that was recorded by the user's camera / microphone is available.
    let recordArrived = null;

    // The audio context helps us show how much sound the microphone is capturing.
    let audioContext = null;

    // The microphone vu meter.
    let vuMeter = null;

    // List of possible resolutions for devices.
    const quickScan = [
        { "width": 3840, "height": 2160 }, { "width": 1920, "height": 1080 }, { "width": 1600, "height": 1200 },
        { "width": 1280, "height":  720 }, { "width":  800, "height":  600 }, { "width":  640, "height":  480 },
        { "width":  640, "height":  360 }, { "width":  352, "height":  288 }, { "width":  320, "height":  240 },
        { "width":  176, "height":  144 }, { "width":  160, "height":  120 }
    ];

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////// CLIENT INITIALIZATION //////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Initializing code for elm app.
    let storedClientConfig = localStorage.getItem('clientConfig');

    if (storedClientConfig === null) {
        localStorage.setItem('clientConfig', JSON.stringify({}));
        flags.global.clientConfig = {};
    } else {
        flags.global.clientConfig = JSON.parse(storedClientConfig);
    }

    let app = Elm.Main.init({
        node, flags
    });

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////// UTIL FUNCTIONS //////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // The class that holds all the necessary elements for measuring sound input level.
    class VuMeter {
        constructor(stream) {
            this.context = new AudioContext();
            this.microphone = this.context.createMediaStreamSource(stream);
            this.node = this.context.createScriptProcessor(2048, 1, 1);

            this.analyser = this.context.createAnalyser();
            this.analyser.smoothingTimeConstant = 0.8;
            this.analyser.fftSize = 1024;

            this.microphone.connect(this.analyser);
            this.analyser.connect(this.node);
            this.node.connect(this.context.destination);

            this.node.onaudioprocess = () => {
                let array = new Uint8Array(this.analyser.frequencyBinCount);
                this.analyser.getByteFrequencyData(array);
                let average = array.reduce((a, b) => a + b, 0) / array.length;
                app.ports.deviceLevel.send(average);
            }
        }

        disconnect() {
            this.analyser.disconnect();
            this.node.disconnect();
            this.microphone.disconnect();
        }
    }

    // Starts the vumeter on a stream, eventually destroying any previous vumeters.
    function startVuMeter(stream) {
        if (vuMeter !== null) {
            vuMeter.disconnect();
        }
        vuMeter = new VuMeter(stream);
    }

    // Unbinds the device if the camera is bound.
    function unbindDevice() {
        if (stream === null || bindingDevice) {
            unbindRequested = true;
            return;
        }

        console.log("Unbinding device");
        stream.getTracks().forEach(function(track) {
            track.stop();
        });
        stream = null;
    }

    // Wrapper for the getUserMedia function.
    // We want to detect device changes, and we can't do that before we asked for permissions with getUserMedia.
    // This function triggers getUserMedia, and checks if the listener for device changes is correctly set, and set it
    // correctly if not.
    async function getUserMedia(args) {
        let response = await navigator.mediaDevices.getUserMedia(args);
        navigator.mediaDevices.ondevicechange = detectDevices;
        startVuMeter(response);
        return response;
    }

    // Detect the devices
    async function detectDevices(elmAskedToDetectDevices = false) {
        if (detectingDevices === true) {
            shouldRedetectDevices = true;
            return;
        }

        let oldDevices = JSON.parse(localStorage.getItem('clientConfig')).devices || { audio: [], video: [] };

        console.log("Detect devices");
        let devices = await navigator.mediaDevices.enumerateDevices();

        let response = {audio: [], video: []};

        for(let i = 0; i < devices.length; i ++) {
            let d = devices[i];

            if (d.kind === 'videoinput') {
                // Try to see if the device has already been detected before.
                let oldDevice = oldDevices.video.filter(x => x.deviceId === d.deviceId)[0];
                if (oldDevice !== undefined) {

                    // If it were, no need to retry every possible resolution.
                    console.log("Fetching parameters for device " + d.label + " from cache");
                    response.video.push(oldDevice);
                    continue;
                }

                console.log("Detecting parameters for device " + d.label);
                let device = {
                    deviceId: d.deviceId,
                    groupId: d.groupId,
                    label: d.label,
                    resolutions: [],
                    available: true,
                };

                // Check all available resolutions for the video device.
                for (let res of quickScan) {
                    let options = {
                        audio: false,
                        video: {
                            deviceId: { exact: d.deviceId },
                            width: { exact: res.width },
                            height: { exact: res.height },
                        },
                    };

                    try {
                        console.log("Trying resolution " + res.width + "x" + res.height);
                        stream = await getUserMedia(options);
                        unbindDevice();
                        console.log("Resolution " + res.width + "x" + res.height + " is working");
                        device.resolutions.push(res);

                    } catch (err) {
                        console.log("Resolution " + res.width + "x" + res.height + " is not working");
                        // Just don't add it
                    }
                }

                console.log("Detection of parameters for device " + d.label + " is finished");

                response.video.push(device);

            } else if (d.kind === 'audioinput') {
                console.log("Detecting parameters for microphone " + d.label);
                d.available = true;
                response.audio.push(d);
            }
        }

        console.log("Detection finished");
        app.ports.detectDevicesResponse.send(response);

        if (elmAskedToDetectDevices === true) {
            app.ports.detectDevicesFinished.send(null);
        }

        if (shouldRedetectDevices) {
            shouldRedetectDevices = false;
            await detectDevices(false);
        }

        detectingDevices = false;
    }

    // Binds a device to the video.
    async function bindDevice(settings) {
        if (unbindRequested) {
            unbindRequested = false;
        }

        if (bindingDevice) {
            shouldRebindDevice = settings;
            return;
        }

        // Unbind device before rebinding it.
        if (stream !== null) {
            await unbindDevice();
        }

        console.log("Binding device");
        bindingDevice = true;

        try {
            stream = await getUserMedia(settings.device);
        } catch (e) {
            console.log(e);
            app.ports.bindingDeviceFailed.send(null);
            return;
        }

        if (unbindRequested) {
            await unbindDevice();
        }

        try {
            await playCurrentStream(true);
        } catch (e) {
            // Maybe the user left the page before this function was done.
            // In that case, the elm client should request itself an unbindDevice, so we don't need to do a lot here.
        }

        recorder = new MediaRecorder(stream, settings.recording);
        recorder.ondataavailable = (data) => {
            recordArrived = data.data;
            // sendRecordToElmIfReady();
        };

        recorder.onerror = (err) => {
            console.log(err);
        };

        bindingDevice = false;

        if (shouldRebindDevice) {
            let newDevice = shouldRebindDevice;
            shouldRebindDevice = null;
            await bindDevice(newDevice);

            // Early return because the client was already notified by the recursive call.
            return;
        }

        console.log("Device bound");
        app.ports.deviceBound.send(null);
    }

    // Plays whathever is in stream in the video element.
    async function playCurrentStream(muted = false) {
        if (stream === null) {
            return;
        }

        await new Promise(requestAnimationFrame);

        let element = document.getElementById("video");

        if (element == null) {
            return;
        }

        element.focus();
        element.srcObject = stream;
        element.src = null;
        element.muted = muted;
        await element.play();
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// PORTS DEFINITION /////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function makePort(name, fn) {
        if (app.ports === undefined) {
            console.warn("app.ports is undefined, not mounting port...");
            return;
        }

        if (app.ports[name + "Port"] === undefined) {
            console.log("app.ports." + name + " is undefined, not mounting port...");
            return;
        }

        app.ports[name + "Port"].subscribe(fn);
    }

    // Saves the client config into the local storage.
    makePort("saveStorage", function(clientConfig) {
        localStorage.setItem('clientConfig', JSON.stringify(clientConfig));
    });

    // Open the file select popup.
    makePort("select", function(args) {
        let project = args[0];
        let mimes = args[1];
        let input = document.createElement('input');
        input.type = 'file';
        input.accept = mimes.join(',');
        input.onchange = function(e) {
            app.ports.selected.send([project, e.target.files[0]]);
        };
        input.click();
    });

    // Detect video and audio devices.
    makePort("detectDevices", () => detectDevices(true));
    makePort("bindDevice", bindDevice);
    makePort("unbindDevice", unbindDevice);
}
