function setupPorts(app) {

    let stream, recorder, recording, blobs, initializing, exitRequested = false, nextSlideCallbacks, backgroundCanvas = document.createElement('canvas'), backgroundBlob, socket;

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

        socket = new WebSocket("ws://" + url);
        socket.onmessage = function(event) {
            app.ports.onWebSocketMessage.send(event.data);
        };
        socket.onopen = function() {
            socket.send(cookie);
        }
    }

    function init(elementId, maybeVideo, maybeBackground) {
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

        function keepWorking() {
            initializing = true;
            setupUserMedia(() => {
                bindWebcam(elementId, () => {
                    initializing = false;
                    if (exitRequested) {
                        exit();
                    } else {
                        app.ports.cameraReady.send(null);
                    }
                });
            });
        }

        if (maybeBackground !== null) {
            let img = new Image();
            img.onload = () => {
                backgroundCanvas.width = img.width;
                backgroundCanvas.height = img.height;
                backgroundCanvas.getContext('2d').drawImage(img, 0, 0, backgroundCanvas.width, backgroundCanvas.height);
                keepWorking();
            };
            img.src = maybeBackground;
        } else {
            keepWorking();
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

    function setupUserMedia(callback) {
        if (stream !== null) {
            callback(stream);
        } else {
            navigator.mediaDevices.getUserMedia({audio: true, video: true})
                .then(function(returnStream) {
                    stream = returnStream;
                    callback(stream);
                })
                .catch(function(err) {
                    console.log(err);
                });
        }
    }

    function bindWebcam(elementId, callback) {
        let element = document.getElementById(elementId);

        if (element === null) {
            callback();
            return;
        }

        element.focus();

        element.srcObject = stream;
        element.src = null;
        element.muted = true;
        element.play();
        callback();
    }

    function startRecording(callback) {
        if (recording) {
            recording = false;
            recorder.stop();
        }

        let options = {
            audioBitsPerSecond : 128000,
            videoBitsPerSecond : 2500000,
            mimeType : 'video/webm;codecs=opus,vp8'
        };

        recorder = new MediaRecorder(stream, options);
        recorder.ondataavailable = (data) => {
            blobs.push(data.data);
        };

        callback(Math.round(performance.now()));
        recorder.start();
    }

    function stopRecording() {
        recorder.stop();
    }

    function goToWebcam(id) {
        clearCallbacks();
        bindWebcam(id, () => {
            app.ports.cameraReady.send(null);
        });
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

        var xhr = new XMLHttpRequest();
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
        var el = document.createElement('textarea');
        el.value = str;
        el.setAttribute('readonly', '');
        el.style = {position: 'absolute', left: '-9999px'};
        document.body.appendChild(el);
        el.select();
        document.execCommand('copy');
        document.body.removeChild(el);
    }

    subscribe(app.ports.init, function(args) {
        init(args[0], args[1], args[2]);
    });

    subscribe(app.ports.initWebSocket, function(args) {
        initWebSocket(args[0], args[1]);
    })

    subscribe(app.ports.bindWebcam, function(id) {
        setupUserMedia(() => {
            bindWebcam(id, () => {
                app.ports.cameraReady.send(null);
            });
        });
    });

    subscribe(app.ports.startRecording, function() {
        startRecording(function(n) {
            app.ports.newRecord.send(n);
        });
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

}
