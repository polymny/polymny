function init(node, flags) {

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////// GLOBAL VARIABLES FOR THE ACQUISITION PHASE ////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // The stream of the webcam.
    let stream = null;

    // Wether the camera is currently being bound.
    let bindingWebcam = false;

    // Whether the user asked to unbind the camera while it was not unbindable.
    let unbindRequested = false;

    // List of possible resolutions for webcams.
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

    // Unbinds the webcam if the camera is bound.
    function unbindWebcam() {
        if (stream === null || bindingWebcam) {
            unbindRequested = true;
            return;
        }

        console.log("Unbinding webcam");
        stream.getTracks().forEach(function(track) {
            track.stop();
        });
        stream = null;
    }

    // Detect the devices
    async function detectDevices(args) {
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
                    console.log("Fetching parameters for webcam " + d.label + " from cache");
                    response.video.push(oldDevice);

                    // Setup the listener for changes in devices
                    if (navigator.mediaDevices.ondevicechange === null) {
                        // If getUserMedia has never been called, the listener is never changed for safety reasons.
                        // This is why we try an easy getUserMedia right here, before setting up the listener.
                        let options = {
                            audio: false,
                            video: {
                                deviceId: { exact: oldDevice.deviceId },
                            },
                        };

                        await navigator.mediaDevices.getUserMedia(options);
                        navigator.mediaDevices.ondevicechange = detectDevices;
                    }

                    continue;
                }

                console.log("Detecting parameters for webcam " + d.label);
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
                        stream = await navigator.mediaDevices.getUserMedia(options);
                        unbindWebcam();
                        console.log("Resolution " + res.width + "x" + res.height + " is working");
                        device.resolutions.push(res);

                    } catch (err) {
                        console.log("Resolution " + res.width + "x" + res.height + " is not working");
                        // Just don't add it
                    }

                    // Setup the listener for changes in devices
                    if (navigator.mediaDevices.ondevicechange === null) {
                        navigator.mediaDevices.ondevicechange = detectDevices;
                    }

                }

                console.log("Detection of parameters for webcam " + d.label + " is finished");

                response.video.push(device);

            } else if (d.kind === 'audioinput') {
                console.log("Detecting parameters for microphone " + d.label);
                d.available = true;
                response.audio.push(d);
            }
        }

        console.log("Detection finished");
        app.ports.detectDevicesResponse.send(response);
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
    makePort("detectDevices", detectDevices);
}
