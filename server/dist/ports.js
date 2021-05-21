function setupPorts(app) {

    let stream, recorder, recording, blobs, initializing, exitRequested = false, nextSlideCallbacks, backgroundCanvas = document.createElement('canvas'), backgroundBlob, socket, inputs, videoDeviceId, audioDeviceId, resolution, audio;

    const quickScan = [
        {
            "width": 3840,
            "height": 2160,
        },
        {
            "width": 1920,
            "height": 1080,
        },
        {
            "width": 1600,
            "height": 1200,
        },
        {
            "width": 1280,
            "height": 720,
        },
        {
            "width": 800,
            "height": 600,
        },
        {
            "width": 640,
            "height": 480,
        },
        {
            "width": 640,
            "height": 360,
        },
        {
            "width": 352,
            "height": 288,
        },
        {
            "width": 320,
            "height": 240,
        },
        {
            "width": 176,
            "height": 144,
        },
        {
            "width": 160,
            "height": 120,
        }
    ];

    function addImageProcess(src) {
        return new Promise((resolve, reject) => {
            let img = new Image()
            img.onload = () => resolve(img)
            img.onerror = reject
            img.src = src
        })
    }

    function clearCallbacks() {
        for (let callback of nextSlideCallbacks) {
            clearTimeout(callback);
        }
        nextSlideCallbacks = [];
    }

    function initVariables() {
        stream = null;
        recorder = null;
        recording = false;
        initializing = false;
        blobs = [];
        nextSlideCallbacks = [];
        inputs = {};
        videoDeviceId = localStorage.getItem("videoDeviceId"); if (videoDeviceId == undefined) videoDeviceId = null;;
        audioDeviceId = localStorage.getItem("audioDeviceId"); if (audioDeviceId == undefined) audioDeviceId = null;;
        resolution    = null;
        try {
            resolution = JSON.parse(localStorage.getItem("resolution"));
        } catch (e) {
            // Leave it null
        }

        console.log("Video device id: " + videoDeviceId);
        console.log("Video resolution: " + JSON.stringify(resolution));
        console.log("Audio device id: " + audioDeviceId);
    }

    function sendWebSocketMessage(content) {
        if (socket == undefined) {
            throw new Error("Can't send message to undefined socket");
        }

        socket.send(content);
    }

    function initWebSocket(url, cookie) {
        // If the socket exists, and not closing or closed.
        if (socket != undefined && socket.readyState <= 2) {
            return;
        }

        socket = new WebSocket(url);
        socket.onmessage = function(event) {
            app.ports.onWebSocketMessage.send(event.data);
        };
        socket.onopen = function() {
            socket.send(cookie);
        }
    }

    async function init(elementId, maybeVideo, maybeBackground) {
        if (exitRequested) {
            exitRequested = false;
        }

        if (initializing) {
            return;
        }

        initVariables();

        if (maybeVideo !== null) {
            blobs.push(maybeVideo);
        }

        await navigator.mediaDevices.getUserMedia({audio: true, video: true});

        let devices = await navigator.mediaDevices.enumerateDevices();
        inputs = {
            video: [{disabled: true}],
            audio: [],
        };

        for(let i = 0; i < devices.length; i ++) {
            let d = devices[i];
            if (d.kind === 'videoinput') {
                let device = {
                    deviceId: d.deviceId,
                    groupId: d.groupId,
                    label: d.label,
                    resolutions: [],
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
                        await navigator.mediaDevices.getUserMedia(options);
                        device.resolutions.push(res);
                    } catch (err) {
                        // Just don't add it
                    }

                }

                inputs.video.push(device);

            } else if (d.kind === 'audioinput') {
                inputs.audio.push(d);
            }
        };

        async function keepWorking() {
            initializing = true;
            await setupUserMedia();
            await bindWebcam(elementId);
            initializing = false;
            if (exitRequested) {
                exit();
            } else {
                app.ports.cameraReady.send(inputs);
            }
        }

        if (maybeBackground !== null) {
            let img = await addImageProcess(maybeBackground);
            backgroundCanvas.width = img.width;
            backgroundCanvas.height = img.height;
            backgroundCanvas.getContext('2d').drawImage(img, 0, 0, backgroundCanvas.width, backgroundCanvas.height);
            await keepWorking();
        } else {
            await keepWorking();
        }

    }

    function captureBackground(elementId) {
        let element = document.getElementById(elementId);

        if (element === null) {
            return;
        }

        let i = 5;
        app.ports.secondsRemaining.send(i);

        function lambda() {
            setTimeout(() => {
                i--;
                app.ports.secondsRemaining.send(i);
                if (i === 0) {
                    backgroundCanvas.width = element.videoWidth;
                    backgroundCanvas.height = element.videoHeight;
                    backgroundCanvas.getContext('2d').drawImage(element, 0, 0, backgroundCanvas.width, backgroundCanvas.height);

                    backgroundCanvas.toBlob(function(blob) {
                        backgroundBlob = blob;

                        let url = URL.createObjectURL(blob);
                        app.ports.backgroundCaptured.send(url);

                        // For debug purposes
                        // let newImg = document.createElement('img'),
                        // newImg.onload = function() {
                        //     backgroundBlob = blob;
                        //     console.log(newImg);
                        // };

                        // newImg.src = url;
                    });


                } else {
                    lambda();
                }
            }, 1000);
        }

        lambda();

    }

    async function setupUserMedia(secondRun) {

        if (stream !== null) {
            return;
        }

        let options = {};

        if (audioDeviceId) {
            options.audio = { deviceId: { exact: audioDeviceId }};
        } else  {
            options.audio = audioDeviceId !== "";
        }

        if (videoDeviceId) {
            options.video = { deviceId: { exact: videoDeviceId }};
            if (resolution) {
                options.video.width = { exact: resolution.width };
                options.video.height = { exact: resolution.height };
            }
        }

        if (options.video === undefined) {
            let input = inputs.video[0];
            if (input.disabled === true) {
                options.video = false;
            } else {
                options.video = { deviceId: { exact: input.deviceId } };
            }
        }

        if (videoDeviceId === "") {
            options.video = false;
        }

        if (resolution === null && options.video !== false) {
            // Find camera by deviceId
            let input = inputs.video.find(element => element.deviceId === options.video.deviceId.exact);
            if (input === undefined) {
                options.video = true;
            } else if (input.disabled === true) {
                options.video = false;
            } else {
                options.video.width = input.resolutions[0].width;
                options.video.height = input.resolutions[0].height;
            }
        }

        try {
            stream = await navigator.mediaDevices.getUserMedia(options);
        } catch (err) {
            if (secondRun) {
                console.error("Could not set webcam");
                return;
            } else if (err.name === "OverconstrainedError") {
                setAudioAndVideoDevice(null, null);
                await setupUserMedia(true);
            } else {
                console.log(err);
                setAudioAndVideoDevice(null, null);
                await setupUserMedia(true);
            }
        }
    }

    async function bindWebcam(elementId) {
        await new Promise(requestAnimationFrame);
        let element = document.getElementById(elementId);

        if (element === null) {
            return;
        }

        element.focus();

        element.srcObject = stream;
        element.src = null;
        element.muted = true;
        element.play();
    }

    function startRecording() {
        if (recording) {
            recording = false;
            recorder.stop();
        }

        let options;
        if (stream.getVideoTracks().length === 0) {
            options = {
                audioBitsPerSecond : 128000,
                mimeType : 'audio/webm;codecs=opus'
            };
        } else if (stream.getAudioTracks().length === 0) {
            options = {
                videoBitsPerSecond : 2500000,
                mimeType : 'video/webm;codecs=vp8'
            };
        } else {
            options = {
                audioBitsPerSecond : 128000,
                videoBitsPerSecond : 2500000,
                mimeType : 'video/webm;codecs=opus,vp8'
            };
        }


        recorder = new MediaRecorder(stream, options);
        recorder.ondataavailable = (data) => {
            blobs.push(data.data);
        };
        recorder.onerror = (err) => {
            console.log(err);
        };

        recorder.start();
    }

    function stopRecording() {
        recorder.stop();
    }

    async function goToWebcam(id) {
        clearCallbacks();
        await bindWebcam(id);
        app.ports.cameraReady.send(inputs);
    }

    function goToStream(id, n, nextSlides) {
        clearCallbacks();

        let video = document.getElementById(id);
        video.srcObject = null;
        if (typeof blobs[n] === "string" || blobs[n] instanceof String) {
            video.src = blobs[n];
        } else {
            video.src = URL.createObjectURL(blobs[n]);
        }
        video.muted = false;
        video.play();
        for (let time of nextSlides) {
            nextSlideCallbacks.push(setTimeout(() => app.ports.goToNextSlide.send(null), time));
        }
    }

    function uploadStream(url, n, json) {
        let streamToUpload = blobs[n];

        let formData = new FormData();
        formData.append("file", streamToUpload);
        formData.append("background", backgroundBlob);
        formData.append("structure", JSON.stringify(json));

        let xhr = new XMLHttpRequest();
        xhr.open("POST", url, true);
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200) {
                app.ports.streamUploaded.send(JSON.parse(xhr.responseText));
            }
        }
        xhr.send(formData);
    }

    function exit() {
        if (stream !== null && !initializing) {
            stream.getTracks().forEach(function(track) {
                track.stop();
            });

            initVariables();
        } else {
            exitRequested = true;
        }
    }

    function subscribe(object, fun) {
        if (object !== undefined) {
            object.subscribe(fun);
        }
    }

    function scrollIntoView(anchor) {
        let element = document.getElementById(anchor);
        if (element !== null) {
            element.scrollIntoView();
        }
    }

    function copyStringToClipboard(str) {
        let el = document.createElement('textarea');
        el.value = str;
        el.setAttribute('readonly', '');
        el.style = {position: 'absolute', left: '-9999px'};
        document.body.appendChild(el);
        el.select();
        document.execCommand('copy');
        document.body.removeChild(el);
    }

    function setAudioAndVideoDevice(arg1, arg2) {
        audioDeviceId = arg1;
        videoDeviceId = arg2;
        if (arg1 === null) {
            localStorage.removeItem("audioDeviceId");
        } else {
            localStorage.setItem("audioDeviceId", audioDeviceId);
        }

        if (arg2 === null) {
            localStorage.removeItem("videoDeviceId");
        } else {
            localStorage.setItem("videoDeviceId", videoDeviceId);
        }
    }

    async function setAudioDevice(arg, id) {
        audioDeviceId = arg;
        localStorage.setItem("audioDeviceId", audioDeviceId);
        stream = null;
        await setupUserMedia();
        await bindWebcam(id);
        app.ports.cameraReady.send(inputs);
    }

    async function setVideoDevice(arg, id) {
        videoDeviceId = arg;
        localStorage.setItem("videoDeviceId", videoDeviceId);
        stream = null;
        await setupUserMedia();
        await bindWebcam(id);
        app.ports.cameraReady.send(inputs);
    }

    async function setResolution(width, height, id) {
        resolution = { width, height };
        localStorage.setItem("resolution", JSON.stringify(resolution));
        stream = null;
        await setupUserMedia();
        await bindWebcam(id);
        app.ports.cameraReady.send(inputs);
    }

    function clearDevices() {
        setAudioAndVideoDevice(null, null);
    }

    subscribe(app.ports.init, function(args) {
        init(args[0], args[1], args[2]);
    });

    subscribe(app.ports.initWebSocket, function(args) {
        initWebSocket(args[0], args[1]);
    })

    subscribe(app.ports.bindWebcam, async function(id) {
        await setupUserMedia();
        await bindWebcam(id);
        app.ports.cameraReady.send(inputs);
    });

    subscribe(app.ports.startRecording, function() {
        startRecording();
        app.ports.newRecord.send(Math.round(performance.now()));
    });

    subscribe(app.ports.stopRecording, function() {
        stopRecording();
    });

    subscribe(app.ports.goToWebcam, function(attr) {
        goToWebcam(attr);
    });

    subscribe(app.ports.goToStream, function(attr) {
        goToStream(attr[0], attr[1], attr[2]);
    });

    subscribe(app.ports.uploadStream, function(attr) {
        uploadStream(attr[0], attr[1], attr[2]);
    });

    subscribe(app.ports.exit, function() {
        exit();
    });

    subscribe(app.ports.askNextSlide, function() {
        app.ports.nextSlideReceived.send(Math.round(performance.now()));
    });

    subscribe(app.ports.captureBackground, function(attr) {
        captureBackground(attr);
    });

    subscribe(app.ports.scrollIntoView, function(arg) {
        scrollIntoView(arg)
    });

    subscribe(app.ports.copyString, function(arg) {
        copyStringToClipboard(arg)
    });

    subscribe(app.ports.setAudioDevice, function(arg) {
        setAudioDevice(arg[0], arg[1]);
    });

    subscribe(app.ports.setVideoDevice, function(arg) {
        setVideoDevice(arg[0], arg[1]);
    });

    subscribe(app.ports.setResolution, function(arg) {
        setResolution(arg[0][0], arg[0][1], arg[1]);
    });

    subscribe(app.ports.clearDevices, function() {
        clearDevices();
    });

}
