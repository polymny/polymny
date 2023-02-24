function init(node, flags) {

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////// GLOBAL VARIABLES FOR THE ACQUISITION PHASE ////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // The stream of the device.
    let stream = null;

    // The device the stream is using.
    let currentSettings = null;

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

    // The id of the video element.
    const videoId = "video";

    // The audio and video for the level checks when adding soundtracks.
    let soundtrackCheck = {
        audio: new Audio(),
        video: document.createElement('video'),
    };

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

    // dbg! like in rust (logs and returns the value).
    function dbg(arg) {
        console.log(arg);
        return arg;
    }

    // Make setTimeout with async/await.
    function sleep(duration) {
        return new Promise(function(resolve, _reject) {
            setTimeout(resolve, duration);
        })
    }

    // Make XML HTTP requests with async/await.
    function makeRequest(method, url, data, onprogress) {
        return new Promise(function (resolve, reject) {
            let xhr = new XMLHttpRequest();
            xhr.open(method, url, true);
            xhr.onload = function () {
                if (this.status >= 200 && this.status < 300) {
                    resolve(xhr);
                } else {
                    reject({
                        status: this.status,
                        statusText: xhr.statusText
                    });
                }
            };
            xhr.onerror = function () {
                reject({
                    status: this.status,
                    statusText: xhr.statusText
                });
            };
            if (typeof onprogress === 'function') {
                xhr.upload.onprogress = onprogress;
            }
            xhr.send(data);
        });
    }

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
        currentSettings = null;
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

        let clientConfig = JSON.parse(localStorage.getItem('clientConfig'));
        let oldDevices = clientConfig.devices || { audio: [], video: [] };

        console.log("Detect devices");

        let devices = await navigator.mediaDevices.enumerateDevices();
        let audioDeviceId = null;
        let videoDeviceId = null;

        if (clientConfig.preferredDevice === undefined || cameraDeviceId !== null) {
            // We don't have authorization to the media devices, so we can't read the labels.
            // This is not good at all, so we will ask for the media device permission.
            let tmp = await getUserMedia({
                video: cameraDeviceId === null ? devices.filter(d => d.kind === "videoinput").length > 0 : { deviceId: { exact: cameraDeviceId } },
                audio: cameraDeviceId === null,
            });

            audioDeviceId = cameraDeviceId === null ? tmp.getAudioTracks()[0].getSettings().deviceId : null;
            videoDeviceId = devices.filter(d => d.kind === "videoinput").length > 0 ? tmp.getVideoTracks()[0].getSettings().deviceId : null;

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

        // If device changed, unbind previous device before binding the new one.
        if (JSON.stringify(settings) !== JSON.stringify(currentSettings)) {
            if (stream !== null) {
                await unbindDevice();
            }

            console.log("Binding device");
            bindingDevice = true;

            try {
                stream = await getUserMedia(settings.device);
                currentSettings = settings;
            } catch (e) {
                console.log(e);
                app.ports.bindingDeviceFailed.send(null);
                return;
            }
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

        if (unbindRequested) {
            await unbindDevice();
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

        let element = document.getElementById(videoId);

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

    // Plays a specific record.
    async function playRecord(record) {
        // let pointerCanvas;
        let video = document.getElementById(videoId);
        video.srcObject = null;
        video.muted = false;

        if (typeof record.webcam_blob === "string" || record.webcam_blob instanceof String) {
            video.src = record.webcam_blob;
        } else {
            video.src = URL.createObjectURL(record.webcam_blob);
        }

        video.onended = () => {
            app.ports.playRecordFinished.send(null);
            bindDevice(currentSettings);
            // let extra = document.getElementById('extra');
            // if (extra instanceof HTMLVideoElement) {
            //     extra.pause();
            //     extra.currentTime = 0;
            // }
            // app.ports.playRecordFinished.send(null);
        };

        // Manage pointer
        // if (record.pointer_blob !== null) {
        //     pointerCanvas = document.getElementById('pointer-canvas');

        //     if (typeof record.pointer_blob === "string" || record.pointer_blob instanceof String) {
        //         pointerVideo.src = record.pointer_blob;
        //     } else {
        //         pointerVideo.src = URL.createObjectURL(record.pointer_blob);
        //     }
        // }

        // Manage slides
        // // Skip last transition which is the end of the video.
        // for (let i = 0; i < record.events.length - 1; i++) {
        //     let event = record.events[i];
        //     let callback;
        //     switch (event.ty) {
        //         case "next_slide":
        //             callback = () => app.ports.nextSlideReceived.send(null);
        //             break;

        //         case "play":
        //             callback = () => {
        //                 let extra = document.getElementById('extra');
        //                 extra.muted = true;
        //                 extra.currentTime = 0;
        //                 extra.play();
        //             };
        //             break;

        //         case "stop":
        //             callback = () => {
        //                 let extra = document.getElementById('extra');
        //                 extra.currentTime = 0;
        //                 extra.stop();
        //             };
        //             break;
        //     }

        //     if (callback !== undefined) {
        //         nextSlideCallbacks.push(setTimeout(callback, event.time));
        //     }
        // }

        video.play();

        // Render pointer
        // if (pointerCanvas !== undefined) {
        //     pointerVideo.play();
        //     renderPointer();
        // }

        // function renderPointer() {
        //     if (video.paused || video.ended) {
        //         ctx.clearRect(0, 0, pointerCanvas.width, pointerCanvas.height);
        //         return;
        //     }

        //     tmpCtx.clearRect(0, 0, tmpCanvas.width, tmpCanvas.height);
        //     tmpCtx.drawImage(pointerVideo, 0, 0);
        //     let frame = tmpCtx.getImageData(0, 0, tmpCanvas.width, tmpCanvas.height);
        //     let length = frame.data.length;
        //     let data = frame.data;

        //     for (let i = 0; i < length; i += 4) {
        //         let channelAvg = (data[i] + data[i+1] + data[i+2]) / 3;
        //         let threshold = channelAvg > 50;
        //         if (!threshold) {
        //             data[i+3] = 0;
        //         }
        //     }

        //     ctx.clearRect(0, 0, pointerCanvas.width, pointerCanvas.height);
        //     ctx.putImageData(frame, 0, 0);

        //     requestAnimationFrame(renderPointer);

        // }
    }

    // Stops the current record.
    function stopRecord() {
        app.ports.playRecordFinished.send(null);
        bindDevice(currentSettings);
    }

    // Uploads a record to the server.
    async function uploadRecord(args) {
        console.log(args);
        let capsuleId = args[0];
        let gos = args[1];
        let record = args[2];

        console.log("upload record");
        let xhr = await makeRequest("POST", "/api/upload-record/" + capsuleId + "/" + gos, record.webcam_blob, (e) => {
            app.ports.taskProgress.send({
                "task": {
                    "type": "UploadRecord",
                    "capsuleId": capsuleId,
                    "gos": gos,
                    "value": record,
                },
                "progress": 0.01 // e.loaded / e.total
            });
        });

        let capsule = JSON.parse(xhr.responseText);
        capsule.structure[gos].events = record.events;
        await makeRequest("POST", "/api/update-capsule/", JSON.stringify(capsule));

        // Debug thingy where we pretend the request is slow.
        for (let i = 1; i <= 50; i++) {
            await sleep(200);
            app.ports.taskProgress.send({
                "task": {
                    "type": "UploadRecord",
                    "capsuleId": capsuleId,
                    "gos": gos,
                    "value": record,
                },
                "progress": i / 50,
                "finished": i === 50,
            });
        }

        // app.ports.capsuleUpdated.send(capsule);
    }



    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////// PORTS DEFINITION /////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Helper to easily make ports.
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

    // Sets the pointer capture to follow an element the right way.
    makePort("setPointerCapture", function setPointerCapture(args) {
        let id = args[0];
        let pointerId = args[1];
        let element = document.getElementById(id);
        if (element === null) {
            console.error("Cannot set pointer capture of null element");
            return;
        }

        element.setPointerCapture(pointerId);
    });

    // Open the file select popup.
    makePort("selectTrack", function(mimes) {
        let input = document.createElement('input');
        input.type = 'file';
        input.accept = mimes.join(',');
        input.onchange = function(e) {
            app.ports.selectedTrack.send(e.target.files[0]);
        };
        input.click();
    });

    // Play sound track.
    makePort("playTrackPreview", function(args) {
        // Extract args.
        let trackPath = args[0];
        let recordPath = args[1];
        let volume = args[2];

        // Nothing to do if no track.
        if (trackPath === null) {
            return;
        }

        // Play track.
        soundtrackCheck.audio = new Audio();
        soundtrackCheck.audio.src = trackPath;
        soundtrackCheck.audio.autoplay = true;
        soundtrackCheck.audio.hidden = true;
        soundtrackCheck.audio.loop = true;
        soundtrackCheck.audio.volume = volume;

        // Track only if no record.
        if (recordPath === null) {
            soundtrackCheck.audio.loop = false;
            soundtrackCheck.audio.addEventListener('ended', () => {
                app.ports.recordEnded.send();
            });
            return;
        }

        // Play record.
        soundtrackCheck.video = document.createElement('video');
        soundtrackCheck.video.src = recordPath;
        soundtrackCheck.video.autoplay = true;
        soundtrackCheck.video.hidden = true;
        soundtrackCheck.video.addEventListener('ended', () => {
            soundtrackCheck.audio.pause();
            soundtrackCheck.audio.currentTime = 0;
            app.ports.recordEnded.send();
        });
    });

    // Stop sound track.
    makePort("stopTrackPreview", function() {
        soundtrackCheck.audio.pause();
        soundtrackCheck.audio.currentTime = 0;

        soundtrackCheck.video.pause();
        soundtrackCheck.video.currentTime = 0;
    });

    // Volume changed.
    makePort("volumeChanged", function(volume) {
        if (soundtrackCheck.audio !== null) {
            soundtrackCheck.audio.volume = volume;
        }
    });

    makePort("detectDevices", (cameraDeviceId) => detectDevices(true, cameraDeviceId));
    makePort("bindDevice", bindDevice);
    makePort("unbindDevice", unbindDevice);
    makePort("registerEvent", registerEvent);
    makePort("startRecording", startRecording);
    makePort("stopRecording", stopRecording);
    makePort("playRecord", playRecord);
    makePort("stopRecord", stopRecord);
    makePort("uploadRecord", uploadRecord);
}
