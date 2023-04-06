function init(node, flags) {

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// GLOBAL VARIABLES FOR THE ACQUISITION PHASE ////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Whether the user has premium account or not.
    let isPremium = flags.user !== null && flags.user.plan !== 'free';

    // The websocket that allows the server to send messages to the client.
    let socket = null;

    // If set to true, the browser will display a popup when the user tries to close the window or move somewhere else.
    let beforeUnloadValue = false;

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

    // The callbacks that trigger a change of slide or sentences during the replay of a record.
    let nextSlideCallbacks = [];

    // Whether there is a request to clear the pointer canvas and remove the callbacks.
    let clearRequested = false;

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

    // The information about the pointer.
    let pointer = {
        mode: "Pointer",
        color: "rgb(255,0,0)",
        size: 10,
        position: { x: 0, y: 0 },
        oldPosition: null,
        down: false,
    };

    // The recorder that will record the pointer.
    let pointerRecorder = null;

    // The video that was recording on the canvas in which the user may have or may have not drawn.
    let pointerArrived = null;

    // Which record are we recording the pointer to, null if its a new record, array containing the index of the record
    // and the record itself otherwise.
    let recordingPointerForRecord = null;

    // Whether the pointer has been touched at some point and we need to take pointer blob into consideraton.
    let pointerExists = false;

    // Video of the pointer for replaying a record with pointer.
    let pointerVideo = document.createElement('video');

    // A temporary canvas to use as a transition before rendering the replay of the pointer.
    let tmpCanvas = document.createElement('canvas');
    tmpCanvas.width = 1920;
    tmpCanvas.height = 1080;

    // The context of the temporary canvas.
    let tmpCtx = tmpCanvas.getContext('2d');

    // List of possible resolutions for devices.
    const quickScan = [
        { "width": 1920, "height": 1080 }, { "width": 1280, "height": 720 }, { "width": 800, "height": 600 },
        { "width": 640, "height": 480 }, { "width": 640, "height": 360 }, { "width": 320, "height": 240 },
    ];

    // The list of requests.
    let requests = {};

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////// CLIENT INITIALIZATION //////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Set onbeforeunload listener.
    window.addEventListener('beforeunload', function () {
        if (beforeUnloadValue) {
            event.preventDefault();
            event.returnValue = '';
        } else {
            delete event["returnValue"];
        }
    });

    // Initializing code for elm app.
    let storedClientConfig = localStorage.getItem('clientConfig');

    if (storedClientConfig === null) {
        localStorage.setItem('clientConfig', JSON.stringify({}));
        flags.global.clientConfig = {};
    } else {
        flags.global.clientConfig = JSON.parse(storedClientConfig);
    }

    // Initializing code for websocket
    function initWebSocket() {
        socket = new WebSocket(flags.global.serverConfig.socketRoot);

        socket.onopen = function () {
            app.ports.webSocketStatus.send(true);
            socket.send(flags.user.cookie);
        }

        socket.onclose = function () {
            // Automatically reconnect
            app.ports.webSocketStatus.send(false);
            setTimeout(initWebSocket, 1000);
        }

        socket.onmessage = function (event) {
            let parsed = JSON.parse(event.data);
            console.log(parsed);
            app.ports.webSocketMsg.send(parsed);
        }
    }

    if (flags.user !== null) {
        initWebSocket();
    }

    // These two listeners add or remove titles (tooltips) depending on whether the element overflows or not.
    document.addEventListener('mouseover', function (event) {
        var target = event.target;

        if (!target.classList.contains("might-overflow")) {
            return;
        }

        var title = target.title || target.getAttribute('data-title') || target.textContent;
        var overflowed = target.scrollWidth > target.clientWidth;

        target.title = overflowed ? title : '';
    });

    document.addEventListener('mouseout', function (event) {
        var target = event.target;

        if (!target.classList.contains("might-overflow")) {
            return;
        }

        if (event.relatedTarget.parentNode === target) return;

        target.title = '';
    });

    // Start app
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
        return new Promise(function (resolve, _reject) {
            setTimeout(resolve, duration);
        })
    }

    // Helper for our requests.
    class PolymnyRequest {
        constructor(method, url, data, onprogress) {
            this.data = data;
            this.xhr = new XMLHttpRequest();
            this.xhr.open(method, url, true);

            if (typeof onprogress === 'function') {
                this.xhr.upload.onprogress = onprogress;
            }
        }

        abort() {
            this.xhr.abort();
        }

        send() {
            return new Promise((resolve, reject) => {
                this.xhr.onload = function () {
                    if (this.status >= 200 && this.status < 300) {
                        resolve(this);
                    } else {
                        reject({
                            status: this.status,
                            statusText: this.statusText
                        });
                    }
                };
                this.xhr.onerror = function () {
                    reject({
                        status: this.status,
                        statusText: this.statusText
                    });
                };
                this.xhr.send(this.data);
            });
        }
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

        if (recording) {
            console.log("Stopping recording");
            stopRecording();
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

        let response = { audio: [], video: [] };

        for (let i = 0; i < devices.length; i++) {
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
                bindingDevice = false;
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

        if (clearRequested) {
            clearPointerAndCallbacks();
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

            pointerExists = false;
            recordingPointerForRecord = null;

            recording = true;
            recorder.start();

            if (isPremium) {
                pointerRecorder.start();
            }

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

    // Starts the recording but only for the pointer.
    function startPointerRecording(args) {
        if (recorder !== undefined && !recording) {
            let index = args[0];
            let record = args[1];

            // Sets the recording state
            recording = true;
            recordingPointerForRecord = [index, record];
            pointerExists = false;

            // Read the previous webcam record while the user is recording the pointer
            let video = document.getElementById(videoId);
            video.srcObject = null;

            video.muted = false;

            if (typeof record.webcam_blob === "string" || record.webcam_blob instanceof String) {
                video.src = record.webcam_blob;
            } else {
                video.src = URL.createObjectURL(record.webcam_blob);
            }

            video.onended = () => {
                // let extra = document.getElementById('extra');
                // if (extra instanceof HTMLVideoElement) {
                //     extra.pause();
                //     extra.currentTime = 0;
                // }

                pointerRecorder.stop();
                recording = false;
                app.ports.recordPointerFinished.send(null);
                bindDevice(currentSettings);
            };

            // Skip last transition which is the end of the video.
            for (let i = 0; i < record.events.length - 1; i++) {
                let event = record.events[i];
                let callback;
                switch (event.ty) {
                    case "next_slide":
                    case "next_sentence":
                        callback = () => app.ports.nextSentenceReceived.send(null);
                        break;

                    // case "play":
                    //     callback = () => {
                    //         let extra = document.getElementById('extra');
                    //         extra.muted = true;
                    //         extra.currentTime = 0;
                    //         extra.play();
                    //     };
                    //     break;

                    // case "stop":
                    //     callback = () => {
                    //         let extra = document.getElementById('extra');
                    //         extra.currentTime = 0;
                    //         extra.stop();
                    //     };
                    //     break;
                }

                if (callback !== undefined) {
                    nextSlideCallbacks.push(setTimeout(callback, event.time));
                }

            }

            video.play();
            pointerRecorder.start();

            // let extra = document.getElementById('extra');
            // if (extra instanceof HTMLVideoElement) {
            //     extra.muted = true;
            //     extra.currentTime = 0;
            //     extra.play();
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

            if (isPremium) {
                pointerRecorder.stop();
            }

            recording = false;
        }
    }

    // Sends the record and all the information so that elm can manage it.
    function sendRecordToElmIfReady() {
        if ((recordArrived === null && recordingPointerForRecord === null) || (isPremium && pointerArrived === null)) {
            return;
        }

        // On this port, we need to send two values
        app.ports.recordArrived.send([

            // The index of the record to which we want to add the pointer (if any)
            recordingPointerForRecord === null ? null : recordingPointerForRecord[0],

            // The record itself
            {
                webcam_blob: recordingPointerForRecord === null ? recordArrived : recordingPointerForRecord[1].webcam_blob,
                pointer_blob: (isPremium && pointerExists) ? pointerArrived : null,
                events: recordingPointerForRecord === null ? currentEvents : recordingPointerForRecord[1].events,
                matted: 'idle',
            }
        ]);

        recordArrived = null;
        pointerArrived = null;
    }

    // Registers an event in the currentEvents array.
    function registerEvent(eventType) {
        currentEvents.push({
            ty: eventType,
            time: Math.round(window.performance.now() - currentEvents[0].time),
        });
    }

    function clearPointerAndCallbacks(pointerCanvas, pointerCtx) {
        if (pointerCtx != undefined) {
            pointerCtx.clearRect(0, 0, pointerCanvas.width, pointerCanvas.height);
        }

        for (let timeoutId of nextSlideCallbacks) {
            clearTimeout(timeoutId);
        }

        nextSlideCallbacks = [];
        clearRequested = false;
    }

    // Plays a specific record.
    async function playRecord(record) {
        let pointerCanvas = null, pointerCtx = null;

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
        if (record.pointer_blob !== null) {
            pointerCanvas = document.getElementById('pointer-canvas');

            if (typeof record.pointer_blob === "string" || record.pointer_blob instanceof String) {
                pointerVideo.src = record.pointer_blob;
            } else {
                pointerVideo.src = URL.createObjectURL(record.pointer_blob);
            }
        }

        // Render pointer
        if (pointerCanvas !== null) {
            pointerCtx = pointerCanvas.getContext('2d');
        }

        clearPointerAndCallbacks(pointerCanvas, pointerCtx);


        // Manage slides
        // Skip last transition which is the end of the video.
        for (let i = 0; i < record.events.length - 1; i++) {
            let event = record.events[i];
            let callback;
            switch (event.ty) {
                case "next_sentence":
                case "next_slide":
                    callback = () => app.ports.nextSentenceReceived.send(null);
                    break;

                // case "play":
                //     callback = () => {
                //         let extra = document.getElementById('extra');
                //         extra.muted = true;
                //         extra.currentTime = 0;
                //         extra.play();
                //     };
                //     break;

                // case "stop":
                //     callback = () => {
                //         let extra = document.getElementById('extra');
                //         extra.currentTime = 0;
                //         extra.stop();
                //     };
                //     break;
            }

            if (callback !== undefined) {
                nextSlideCallbacks.push(setTimeout(callback, event.time));
            }
        }

        video.play();

        if (pointerCanvas !== null) {
            pointerVideo.play();
            renderPointer();
        }

        function renderPointer() {
            if (video.paused || video.ended || clearRequested) {
                pointerCtx.clearRect(0, 0, pointerCanvas.width, pointerCanvas.height);

                for (let timeoutId of nextSlideCallbacks) {
                    clearTimeout(timeoutId);
                }

                nextSlideCallbacks = [];
                clearRequested = false;
                return;
            }


            tmpCtx.clearRect(0, 0, tmpCanvas.width, tmpCanvas.height);
            tmpCtx.drawImage(pointerVideo, 0, 0);
            let frame = tmpCtx.getImageData(0, 0, tmpCanvas.width, tmpCanvas.height);
            let length = frame.data.length;
            let data = frame.data;

            for (let i = 0; i < length; i += 4) {
                let channelAvg = (data[i] + data[i + 1] + data[i + 2]) / 3;
                let threshold = channelAvg > 50;
                if (!threshold) {
                    data[i + 3] = 0;
                }
            }

            pointerCtx.clearRect(0, 0, pointerCanvas.width, pointerCanvas.height);
            pointerCtx.putImageData(frame, 0, 0);

            requestAnimationFrame(renderPointer);

        }
    }

    // Stops the current record.
    function stopRecord() {
        app.ports.playRecordFinished.send(null);
        bindDevice(currentSettings);
    }

    // Uploads a record to the server.
    async function uploadRecord(args) {
        // Get arguments.
        let capsuleId = args[0][0];
        let gos = args[0][1];
        let record = args[1][0];
        let taskId = args[1][1];

        let request;

        if (typeof record.webcam_blob === "string" || record.webcam_blob instanceof String) {

            if (typeof record.pointer_blob === "string" || record.pointer_blob instanceof String) {

                // User wants to validate the old record, don't need to do anything,
                // just send the message to let them know it's done
                // app.ports.capsuleUpdated.send(null);

            } else {

                // User just want to send the pointer blob
                if (record.pointer_blob !== null) {
                    try {
                        request = new PolymnyRequest("POST", "/api/upload-pointer/" + capsuleId + "/" + gos, record.pointer_blob, (e) => {
                            app.ports.taskProgress.send({
                                "task": {
                                    "taskId": taskId,
                                    "type": "UploadRecord",
                                    "capsuleId": capsuleId,
                                    "gos": gos,
                                    "value": null,
                                },
                                progress: e.loaded / e.total * (record.pointer_blob === null ? 1 : 0.5),
                                finished: false,
                            });
                        });

                        await request.send();
                        let capsule = JSON.parse(xhr.responseText);
                        // app.ports.capsuleUpdated.send(capsule);
                    } catch (e) {
                        console.log(e)
                        app.ports.uploadRecordFailed.send(null);
                    }
                }

            }

        } else {

            try {

                console.log("upload new record", record);
                let task = {
                    "taskId": taskId,
                    "type": "UploadRecord",
                    "capsuleId": capsuleId,
                    "gos": gos,
                    "value": null,
                };

                let url = "/api/upload-record/" + capsuleId + "/" + gos;
                let tracker = "task-track-" + taskId;
                let request = new PolymnyRequest("POST", url, record.webcam_blob, (e) => {
                    app.ports.taskProgress.send({
                        "task": task,
                        "progress": e.loaded / e.total * (record.pointer_blob === null ? 1 : 0.5),
                        "finished": false,
                        "aborted": false,
                    });
                });

                requests[tracker] = {
                    "task": task,
                    "request": request,
                };

                await request.send();

                delete requests[tracker];

                if (record.pointer_blob !== null) {
                    console.log("upload pointer");
                    let task = {
                        "taskId": taskId,
                        "type": "UploadRecord",
                        "capsuleId": capsuleId,
                        "gos": gos,
                        "value": null,
                    };

                    url = "/api/upload-pointer/" + capsuleId + "/" + gos;
                    tracker = "task-track-" + taskId;
                    request = new PolymnyRequest("POST", url, record.pointer_blob, (e) => {
                        app.ports.taskProgress.send({
                            "task": task,
                            "progress": 0.5 + (e.loaded / e.total) / 2,
                            "finished": false,
                            "aborted": false,
                        });
                    });

                    requests[tracker] = {
                        "task": task,
                        "request": request,
                    };

                    await request.send();

                    delete requests[tracker];

                }

                let capsule = JSON.parse(request.xhr.responseText);
                capsule.structure[gos].events = record.events;
                await (new PolymnyRequest("POST", "/api/update-capsule/", JSON.stringify(capsule)).send());

                app.ports.taskProgress.send({
                    "task": {
                        "taskId": taskId,
                        "type": "UploadRecord",
                        "capsuleId": capsuleId,
                        "gos": gos,
                        "value": capsule.structure[gos].record,
                    },
                    "progress": 1,
                    "finished": true,
                    "aborted": false,
                });

                // app.ports.capsuleUpdated.send(capsule);
            } catch (e) {
                console.log(e)
                app.ports.uploadRecordFailed.send(null);
            }

        }

    }

    // Blur event handler.
    function handleBlur(event, id) {
        let panel = document.getElementById(id);
        if (!panel.contains(event.relatedTarget)) {
            // Blur the panel.
            app.ports.panelBlur.send(id);
        } else {
            // Re-focus the panel.
            panel.focus();
        }
    }

    // Sets up the canvas for pointer or drawing on the slide during recording.
    async function setupCanvas(canvasId) {

        // Wait a second so that the canvas appear in the HTML DOM.
        await new Promise(requestAnimationFrame);

        let canvas = document.getElementById(canvasId);
        canvas.width = 1920;
        canvas.height = 1080;

        let ctx = canvas.getContext('2d');

        pointerStream = canvas.captureStream(30);

        canvas.addEventListener('pointerdown', function (event) {
            pointer.down = true;
            pointer.position.x = event.offsetX * canvas.width / canvas.parentNode.clientWidth;
            pointer.position.y = event.offsetY * canvas.width / canvas.parentNode.clientWidth;
            refresh(canvas, ctx);
            canvas.setPointerCapture(event.pointerId);
        });

        canvas.addEventListener('pointerup', function (event) {
            pointer.down = false;
            refresh(canvas, ctx);
            canvas.releasePointerCapture(event.pointerId);
        });

        canvas.addEventListener('pointermove', function (event) {
            pointer.position.x = event.offsetX * canvas.width / canvas.parentNode.clientWidth;
            pointer.position.y = event.offsetY * canvas.width / canvas.parentNode.clientWidth;
            refresh(canvas, ctx);
        });

        let pointerOptions = {
            videoBitsPerSecond: 2500000,
            mimeType: 'video/webm;codecs=vp8'
        };

        pointerRecorder = new MediaRecorder(pointerStream, pointerOptions);
        pointerRecorder.ondataavailable = (data) => {
            pointerArrived = data.data;
            sendRecordToElmIfReady();
        };

        pointerRecorder.onerror = (err) => {
            console.log(err);
        };
    }

    // Fully refreshes the canvas.
    function refresh(canvas, ctx) {
        if (pointer.mode === "Pointer") {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
        }
        if (pointer.down) {
            pointerExists = true;
            // let gradient = ctx.createRadialGradient(
            //     pointer.position.x, pointer.position.y, 3,
            //     pointer.position.x, pointer.position.y, 10
            // );
            // gradient.addColorStop(0, color);
            // gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');
            ctx.strokeStyle = pointer.color;
            ctx.fillStyle = pointer.color;

            ctx.beginPath();
            ctx.arc(pointer.position.x, pointer.position.y, pointer.size, 0, 2 * Math.PI);
            ctx.fill();

            if (pointer.mode === "Brush") {
                ctx.lineWidth = 2 * pointer.size;

                if (pointer.oldPosition === null) {
                    pointer.oldPosition = pointer.position;
                }

                ctx.beginPath();
                ctx.moveTo(pointer.oldPosition.x, pointer.oldPosition.y);
                ctx.lineTo(pointer.position.x, pointer.position.y);
                ctx.stroke();
            }

            pointer.oldPosition = { x: pointer.position.x, y: pointer.position.y };
        } else {
            pointer.oldPosition = null;
        }
    }

    // A class that export a capsule as a zip file.
    class CapsuleExporter {
        constructor(args) {
            this.capsule = args[0];
            this.taskId = args[1];
            this.aborted = false;
            this.totalSubasks = this.countSubtasks();
        }

        // Starts the export.
        async start() {

            let zip = new JSZip();
            let taskCounter = 0;

            // Export each gos.
            for (let gosIndex = 0; gosIndex < this.capsule.structure.length; gosIndex++) {

                let gos = this.capsule.structure[gosIndex];
                let gosDir = zip.folder(gosIndex + 1);

                // Export slides.
                for (let slideIndex = 0; slideIndex < gos.slides.length; slideIndex++) {

                    let slide = gos.slides[slideIndex];
                    let resp = await fetch("/data/" + this.capsule.id + "/assets/" + slide.uuid + ".png");
                    let blob = await resp.blob();

                    gosDir.file((slideIndex + 1) + ".png", blob);
                    slide.uuid = (gosIndex + 1) + "/" + (slideIndex + 1) + ".png";
                    if (this.updateProgress(++taskCounter / this.totalSubasks / 2)) return;

                    if (slide.extra != undefined) {

                        let resp = await fetch("/data/" + this.capsule.id + "/assets/" + slide.extra + ".mp4");
                        let blob = await resp.blob();

                        gosDir.file((slideIndex + 1) + ".mp4", blob);
                        slide.extra = (gosIndex + 1) + "/" + (slideIndex + 1) + ".mp4";
                        if (this.updateProgress(++taskCounter / this.totalSubasks / 2)) return;

                    }

                }

                // Export record.
                if (gos.record != undefined) {

                    let resp = await fetch("/data/" + this.capsule.id + "/assets/" + gos.record.uuid + ".webm");
                    let blob = await resp.blob();

                    gosDir.file("record.webm", blob);
                    gos.record = (gosIndex + 1) + "/record.webm";
                    if (this.updateProgress(++taskCounter / this.totalSubasks / 2)) return;

                }

            }

            // Export output.
            if (this.capsule.produced) {

                let resp = await fetch("/data/" + this.capsule.id + "/output.mp4");
                let blob = await resp.blob();

                zip.file("output.mp4", blob);
                if (this.updateProgress(++taskCounter / this.totalSubasks / 2)) return;

            }

            // Export osundtrack.
            if (this.capsule.sound_track != undefined) {

                let resp = await fetch("/data/" + this.capsule.id + "/assets/" + this.capsule.sound_track.uuid + ".m4a");
                let blob = await resp.blob();

                zip.file("soundtrack.m4a", blob);
                if (this.updateProgress(++taskCounter / this.totalSubasks / 2)) return;

            }

            // Export structure.
            zip.file("structure.json", JSON.stringify(this.capsule, null, 4));

            // Generate zip.
            let content = await zip.generateAsync({ type: "blob" },
                (metadata) => this.updateProgress(metadata.percent / 200 + 0.5)
            );

            if (this.aborted) return;

            // Send finished to Elm.
            app.ports.taskProgress.send({
                "task": {
                    "taskId": this.taskId,
                    "type": "ExportCapsule",
                    "capsuleId": this.capsule.id,
                },
                "progress": 1,
                "finished": true,
                "aborted": false,
            });

            saveAs(content, this.capsule.id + ".zip");
        }

        // Updates the progress of the task.
        updateProgress(value) {

            // If aborted, indicate that you should early return.
            if (this.aborted) return true;

            // Send progress to Elm.
            app.ports.taskProgress.send({
                "task": {
                    "taskId": this.taskId,
                    "type": "ExportCapsule",
                    "capsuleId": this.capsule.id,
                },
                "progress": value,
                "finished": false,
                "aborted": false,
            });

            return false;
        }

        // Count the number of subtasks.
        countSubtasks() {
            let totalSubasks = 0;

            // Count the number of slides and records.
            for (let gosIndex = 0; gosIndex < this.capsule.structure.length; gosIndex++) {
                let gos = this.capsule.structure[gosIndex];
                if (gos.record) totalSubasks++;

                for (let slideIndex = 0; slideIndex < gos.slides.length; slideIndex++) {
                    totalSubasks++;

                    let slide = gos.slides[slideIndex];
                    if (slide.extra) totalSubasks++;
                }

            }

            // Count the output.
            if (this.capsule.produced) totalSubasks++;

            // Count the soundtrack.
            if (this.capsule.sound_track) totalSubasks++;

            return totalSubasks;
        }

        // Abort the task.
        abort() {
            // Set aborted to true. :)
            this.aborted = true;
        }

    }

    // Exports a capsule into a zip file.
    async function exportCapsule(args) {
        let exportCapsule = new CapsuleExporter(args);

        let tracker = "task-track-" + exportCapsule.taskId;
        requests[tracker] = {
            "task": {
                "taskId": exportCapsule.taskId,
                "type": "ExportCapsule",
                "capsuleId": exportCapsule.capsule.id,
            },
            "request": exportCapsule,
        };

        await exportCapsule.start();

        delete requests[tracker];
    }


    // A class to import a capsule from a zip file.
    class CapsuleImporter {
        constructor(args) {
            this.project = args[0];
            this.capsuleZip = args[1];
            this.taskId = args[2];
            this.capsuleContent = null;
            this.capsule = null;
            this.newCapsule = null;
            this.aborted = false;
            this.totalSubasks = 0;
        }

        // Initializes the importer.
        async init() {

            // Get the zip file.
            let zip = new JSZip();
            this.capsuleContent = await zip.loadAsync(this.capsuleZip);
            this.capsule = await JSON.parse(await this.capsuleContent.file("structure.json").async("string"));
            this.totalSubasks = this.countSubtasks();

            // Creates the empty capsule.
            let resp = await fetch("/api/empty-capsule/" + this.project + "/" + this.capsule.name, { method: "POST" });
            this.newCapsule = await resp.json();
        }

        // Starts the import.
        async start() {

            // Initialize the importer.
            await this.init();

            let taskCounter = 0;
            let resp;

            // Upload the slides.
            for (let gosIndex = 0; gosIndex < this.capsule.structure.length; gosIndex++) {
                let gos = this.capsule.structure[gosIndex];

                for (let slideIndex = 0; slideIndex < gos.slides.length; slideIndex++) {
                    let slide = gos.slides[slideIndex];
                    let image = await this.capsuleContent.file(slide.uuid).async("blob");
                    image = image.slice(0, image.size, "image/png")

                    // Upload the slide.
                    resp = await fetch("/api/add-slide/" + this.newCapsule.id + "/-1/-1", { method: "POST", body: image });
                    this.newCapsule = await resp.json();

                    // Find uuid of the slide we added.
                    let newGos = this.newCapsule.structure[this.newCapsule.structure.length - 1];
                    let newSlide = newGos.slides[newGos.slides.length - 1];

                    slide.uuid = newSlide.uuid;

                    if (this.updateProgress(++taskCounter / this.totalSubasks)) return;
                }

            }

            // Set the correct structure.
            // Remove records because they are currently null.
            let capsuleClone = JSON.parse(JSON.stringify(this.newCapsule));
            for (let gos of capsuleClone.structure) {
                gos.record = null;
                for (let slide of gos.slides) {
                    slide.extra = null;
                }
            }

            // Remove from json attributes that the server doesn't want.
            delete capsuleClone.produced;

            await fetch("/api/update-capsule/", {
                method: "POST",
                body: JSON.stringify(capsuleClone),
                headers: { "Content-Type": "application/json" },
            });

            // Upload the records and extra
            for (let gosIndex = 0; gosIndex < this.capsule.structure.length; gosIndex++) {
                let gos = this.capsule.structure[gosIndex];

                // Upload the gos record if any.
                if (gos.record !== null) {
                    let blob = await this.capsuleContent.file(gos.record).async("blob");
                    blob = blob.slice(0, blob.size, "video/webm");
                    resp = await fetch("/api/upload-record/" + this.newCapsule.id + "/" + gosIndex, { method: "POST", body: blob });
                    this.newCapsule = await resp.json();

                    if (this.updateProgress(++taskCounter / this.totalSubasks)) return;
                }

                // Upload the extra if any.
                for (let slideIndex = 0; slideIndex < gos.slides.length; slideIndex++) {
                    let slide = gos.slides[slideIndex];
                    if (slide.extra !== null) {
                        let blob = await this.capsuleContent.file(slide.extra).async("blob");
                        blob = blob.slice(0, blob.size, "video/mp4");
                        resp = await fetch("/api/replace-slide/" + this.newCapsule.id + "/" + slide.uuid + "/-1", { method: "POST", body: blob });
                        this.newCapsule = await resp.json();

                        if (this.updateProgress(++taskCounter / this.totalSubasks)) return;
                    }
                }
            }

            // Import sound track.
            if (this.capsule.sound_track !== null) {
                let track = await this.capsuleContent.file("soundtrack.m4a").async("blob");
                track = track.slice(0, track.size, "audio/m4a");
                resp = await fetch("/api/sound-track/" + this.newCapsule.id + "/" + this.capsule.sound_track.name, { method: "POST", body: track });
                this.newCapsule = await resp.json();

                if (this.updateProgress(++taskCounter / this.totalSubasks)) return;
            }

            app.ports.capsuleUpdated.send(this.newCapsule);

            // Update the task.
            let task = {
                "taskId": this.taskId,
                "type": "ImportCapsule",
            };
            app.ports.taskProgress.send({
                "task": task,
                "progress": 1,
                "finished": true,
                "aborted": false,
            });
        }

        // Counts the number of subtasks.
        countSubtasks() {

            let totalSubasks = 0;

            for (let gos of this.capsule.structure) {
                // Count the slides.
                totalSubasks += gos.slides.length;

                // Count the records.
                if (gos.record !== null) totalSubasks++;

                // Count the extras.
                for (let slide of gos.slides) {
                    if (slide.extra !== null) totalSubasks++;
                }
            }

            // Count the sound track.
            if (this.capsuleZip.sound_track) totalSubasks++;

            return totalSubasks;
        }

        // Updates the progress of the task.
        updateProgress(value) {

            // If aborted, indicate that you should early return.
            if (this.aborted) {
                fetch("/api/capsule/" + this.json.id, { method: "DELETE" })
                return true;
            }

            let task = {
                "taskId": this.taskId,
                "type": "ImportCapsule",
            };
            app.ports.taskProgress.send({
                "task": task,
                "progress": value,
                "finished": false,
                "aborted": false,
            });

            return false;
        }

        // Aborts the task.
        abort() {
            this.aborted = true;
        }

    }

    // Import a capsule.
    async function importCapsule(args) {
        let importCapsule = new CapsuleImporter(args);

        let tracker = "task-track-" + importCapsule.taskId;
        requests[tracker] = {
            "task": {
                "taskId": importCapsule.taskId,
                "type": "ImportCapsule",
                "capsuleId": importCapsule.capsuleZip.id,
            },
            "request": importCapsule,
        };

        await importCapsule.start();

        delete requests[tracker];
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
            console.warn("app.ports." + name + " is undefined, not mounting port...");
            return;
        }

        app.ports[name + "Port"].subscribe(fn);
    }

    // Scroll to the element view.
    makePort("scrollIntoView", args => {
        let scrollVal = args[0];
        let scrollId = args[1]
        let gosElement = document.getElementById(scrollId);
        gosElement.scrollTo(0, scrollVal * gosElement.scrollHeight)
    })

    // Saves the client config into the local storage.
    makePort("saveStorage", function (clientConfig) {
        localStorage.setItem('clientConfig', JSON.stringify(clientConfig));
    });

    // Open the file select popup.
    makePort("select", function (args) {
        let project = args[0];
        let mimes = args[1];
        let input = document.createElement('input');
        input.type = 'file';
        input.accept = mimes.join(',');
        input.onchange = function (e) {
            app.ports.selected.send([project, e.target.files[0]]);
        };
        input.click();
    });

    // Copies the string to the clipboard.
    makePort("copyString", async function(args) {
        await navigator.clipboard.writeText(args);
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
    makePort("selectTrack", function (mimes) {
        let input = document.createElement('input');
        input.type = 'file';
        input.accept = mimes.join(',');
        input.onchange = function (e) {
            app.ports.selectedTrack.send(e.target.files[0]);
        };
        input.click();
    });

    // Play sound track.
    makePort("playTrackPreview", function (args) {
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
    makePort("stopTrackPreview", function () {
        soundtrackCheck.audio.pause();
        soundtrackCheck.audio.currentTime = 0;

        soundtrackCheck.video.pause();
        soundtrackCheck.video.currentTime = 0;
    });

    // Volume changed.
    makePort("volumeChanged", function (volume) {
        if (soundtrackCheck.audio !== null) {
            soundtrackCheck.audio.volume = volume;
        }
    });

    // Change the mode of the pointer.
    makePort("setPointerStyle", function (argument) {
        pointer.mode = argument.mode;
        pointer.color = argument.color;
        pointer.size = argument.size;
    });

    // Clears the canvas.
    makePort("clearPointer", function (canvasId) {
        let canvas = document.getElementById(canvasId);
        let ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, canvas.width, canvas.height);
    });

    // Handle panel blur.
    makePort("addBlurHandler", id => {
        let panel = document.getElementById(id);
        panel.onblur = event => handleBlur(event, id);
    });

    // Remove task.
    makePort("abortTask", tracker => {
        console.log("Aborting task " + tracker);

        if (tracker in requests) {
            // Abort request.
            requests[tracker].request.abort();

            // Send abort message.
            app.ports.taskProgress.send({
                "task": requests[tracker].task,
                "progress": 1,
                "finished": true,
                "aborted": true
            });
        }
    });

    // Sets the before unload value.
    makePort("onBeforeUnload", function (arg) {
        beforeUnloadValue = arg;
    });

    makePort("detectDevices", (cameraDeviceId) => detectDevices(true, cameraDeviceId));
    makePort("bindDevice", bindDevice);
    makePort("unbindDevice", unbindDevice);
    makePort("registerEvent", registerEvent);
    makePort("startRecording", startRecording);
    makePort("stopRecording", stopRecording);
    makePort("startPointerRecording", startPointerRecording);
    makePort("playRecord", playRecord);
    makePort("stopRecord", stopRecord);
    makePort("uploadRecord", uploadRecord);
    makePort("setupCanvas", setupCanvas);
    makePort("clearPointerAndCallbacks", () => clearRequested = true);
    makePort("exportCapsule", exportCapsule);
    makePort("importCapsule", importCapsule);
}
