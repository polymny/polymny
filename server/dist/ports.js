function setupPorts(app) {

    let stream, recorder, recording, blobs, initializing, exitRequested = false, nextSlideCallbacks;

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

    function init(elementId) {
        if (exitRequested) {
            exitRequested = false;
        }

        if (initializing) {
            return;
        }

        initVariables();
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

    function goToStream(id, n, nextSlides) {
        clearCallbacks();

        if (n === 0) {
            bindWebcam(id, () => {
                app.ports.cameraReady.send(null);
            });
        } else {
            let video = document.getElementById(id);
            video.srcObject = null;
            video.src = URL.createObjectURL(blobs[n-1]);
            video.muted = false;
            video.play();
            for (let time of nextSlides) {
                nextSlideCallbacks.push(setTimeout(() => app.ports.goToNextSlide.send(null), time));
            }
        }
    }

    function uploadStream(url, n) {
        let streamToUpload = blobs[n-1];

        var xhr = new XMLHttpRequest();
        xhr.open("POST", url, true);
        xhr.setRequestHeader("Content-Type", "video/webm");
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4 && xhr.status === 200) {
                app.ports.streamUploaded.send(JSON.parse(xhr.responseText));
            }
        }
        xhr.send(streamToUpload);
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

    subscribe(app.ports.init, function(id) {
        init(id);
    });

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

    subscribe(app.ports.goToStream, function(attr) {
        goToStream(attr[0], attr[1], attr[2]);
    });

    subscribe(app.ports.uploadStream, function(attr) {
        uploadStream(attr[0], attr[1]);
    });

    subscribe(app.ports.exit, function() {
        exit();
    });

    subscribe(app.ports.askNextSlide, function() {
        app.ports.nextSlideReceived.send(Math.round(performance.now()));
    });

}
