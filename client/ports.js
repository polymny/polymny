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

    // Tells whether we are currently recording or not.
    let recording = false;

    // The events that occur during the record (next sentence, next slide, etc...)
    let currentEvents = [];

    // The video that was recorded by the user's camera / microphone is available.
    let recordArrived = null;

    // The audio context helps us show how much sound the microphone is capturing.
    let audioContext = null;

    // The microphone vu meter.
    let vuMeter = null;

    // List of possible resolutions for devices.
    const quickScan = [
        { "width": 1920, "height": 1080 }, { "width": 1280, "height":  720 }, { "width":  800, "height":  600 },
        { "width":  640, "height":  480 }, { "width":  640, "height":  360 }, { "width":  320, "height":  240 },
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
        stream.getTracks().forEach(track => track.stop());
        stream = null;
    }

    // Wrapper for the getUserMedia function.
    // We want to detect device changes, and we can't do that before we asked for permissions with getUserMedia.
    // This function triggers getUserMedia, and checks if the listener for device changes is correctly set, and set it
    // correctly if not.
    async function getUserMedia(args) {
        let response = await navigator.mediaDevices.getUserMedia(args);
        navigator.mediaDevices.ondevicechange = detectDevices;
        return response;
    }

    // Detect the devices
    async function detectDevices(elmAskedToDetectDevices = false, cameraDeviceId = null) {
        if (detectingDevices === true) {
            shouldRedetectDevices = true;
            return;
        }

        let oldDevices = JSON.parse(localStorage.getItem('clientConfig')).devices || { audio: [], video: [] };

        console.log("Detect devices");

        let devices = await navigator.mediaDevices.enumerateDevices();
        let audioDeviceId = null;
        let videoDeviceId = null;

        if (devices.reduce((x, y) => x || y.label === "", false) || cameraDeviceId !== null) {
            // We don't have authorization to the media devices, so we can't read the labels.
            // This is not good at all, so we will ask for the media device permission.
            let tmp = await getUserMedia({
                video: cameraDeviceId === null ? true : { deviceId: { exact: cameraDeviceId } },
                audio: cameraDeviceId === null,
            });

            audioDeviceId = cameraDeviceId === null ? tmp.getAudioTracks()[0].getSettings().deviceId : null;
            videoDeviceId = tmp.getVideoTracks()[0].getSettings().deviceId;

            devices = await navigator.mediaDevices.enumerateDevices();

            tmp.getTracks().forEach(track => track.stop());
        }

        let response = {audio: [], video: []};

        for(let i = 0; i < devices.length; i ++) {
            let d = devices[i];

            if (d.kind === 'videoinput') {
                // Try to see if the device has already been detected before.
                let oldDevice = oldDevices.video.filter(x => x.deviceId === d.deviceId)[0];
                if (oldDevice !== undefined && oldDevice.resolutions.length !== 0) {

                    // If it were, no need to retry every possible resolution.
                    console.log("Fetching parameters for device " + d.label + " from cache");
                    oldDevice.label = d.label;
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

                if (d.deviceId === videoDeviceId) {

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
                            console.log(err);
                            // Just don't add it
                        }
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

        let audioDevice = response.audio.find(x => x.deviceId === audioDeviceId);
        let videoDevice = response.video.find(x => x.deviceId === videoDeviceId);

        console.log((videoDeviceId === null && cameraDeviceId === null) ? null : {
            audio: audioDevice || null,
            video: videoDevice ? [videoDevice, videoDevice.resolutions[0]] : null,
        });

        app.ports.detectDevicesResponse.send({
            devices: response,
            preferredDevice: (videoDeviceId === null && cameraDeviceId === null) ? null : {
                audio: audioDevice || null,
                video: videoDevice ? [videoDevice, videoDevice.resolutions[0]] : null,
            }
        });

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

        startVuMeter(stream);

        recorder = new MediaRecorder(stream, settings.recording);
        recorder.ondataavailable = (data) => {
            recordArrived = data.data;
            sendRecordToElmIfReady();
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

    // Starts the recording.
    function startRecording() {
        if (recorder !== undefined && !recording) {

            // pointerExists = false;
            // recordingPointerForRecord = null;

            recording = true;
            recorder.start();

            // if (isPremium) {
            //     pointerRecorder.start();
            // }

            currentEvents = [{
                time: Math.round(window.performance.now()),
                ty: "start"
            }];

            // let extra = document.getElementById('extra');
            // if (extra instanceof HTMLVideoElement) {
            //     extra.muted = true;
            //     extra.currentTime = 0;
            //     extra.play();
            //     currentEvents.push({
            //         time: 0,
            //         ty: "play"
            //     });
            // }
        }
    }

    // Stops the recording.
    function stopRecording() {
        if (recording) {
            let time = Math.round(window.performance.now()) - currentEvents[0].time;

            // let extra = document.getElementById('extra');
            // if (extra instanceof HTMLVideoElement) {
            //     extra.muted = true;
            //     extra.pause();
            //     extra.currentTime = 0;
            //     currentEvents.push({
            //         ty: "stop",
            //         time: time
            //     });
            // }

            currentEvents.push({
                time: time,
                ty: "end",
            });

            currentEvents[0].time = 0;
            recorder.stop();

            // if (isPremium) {
            //     pointerRecorder.stop();
            // }

            recording = false;
        }
    }

    // Sends the record and all the information so that elm can manage it.
    function sendRecordToElmIfReady() {
        // if ((recordArrived === null && recordingPointerForRecord === null) || (isPremium && pointerArrived === null)) {
        //     return;
        // }

        // let port = recordingPointerForRecord === null ? app.ports.recordArrived : app.ports.pointerRecordArrived;
        // port.send({
        //     webcam_blob: recordingPointerForRecord === null ? recordArrived : recordingPointerForRecord.webcam_blob,
        //     pointer_blob: (isPremium && pointerExists) ? pointerArrived : null,
        //     events: recordingPointerForRecord === null ? currentEvents : recordingPointerForRecord.events,
        //     matted: 'idle',
        // });

        let port = app.ports.recordArrived;
        port.send({
            webcam_blob: recordArrived,
            events: currentEvents,
            matted: 'idle',
        });

        recordArrived = null;
        // pointerArrived = null;
    }

    // Registers an event in the currentEvents array.
    function registerEvent(eventType) {
        currentEvents.push({
            ty: eventType,
            time: Math.round(window.performance.now() - currentEvents[0].time),
        });
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
    makePort("detectDevices", (cameraDeviceId) => detectDevices(true, cameraDeviceId));
    makePort("bindDevice", bindDevice);
    makePort("unbindDevice", unbindDevice);
    makePort("registerEvent", registerEvent);
    makePort("startRecording", startRecording);
    makePort("stopRecording", stopRecording);
}
