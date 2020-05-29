function setupPorts(app) {

    let = {};

    let stream, recorder, recording = false;
    let blobs = [];

    function reset() {
        blobs = [];
        recording = false;
        recorder = null;
    }

    function setupUserMedia(callback) {
        if (stream != undefined) {
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

    function bindWebcam(elementId) {
        let element = document.getElementById(elementId);
        element.srcObject = stream;
        element.src = null;
        element.muted = true;
        element.play();
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
            callback(blobs.length);
        };

        recorder.start();
    }

    function stopRecording() {
        recorder.stop();
    }

    function goToStream(id, n) {
        let source;
        if (n === 0) {
            bindWebcam(id);
        } else {
            let video = document.getElementById(id);
            video.srcObject = null;
            video.src = URL.createObjectURL(blobs[n-1]);
            video.muted = false;
            video.play();
        }
    }

    // app.ports.reset.subscribe(function() {
    //     reset();
    // });

    app.ports.bindWebcam.subscribe(function(id) {
        setupUserMedia(() => {
            bindWebcam(id);
        });
    });

    app.ports.startRecording.subscribe(function() {
        startRecording(function(n) {
            app.ports.recordingsNumber.send(n);
        });
    });

    app.ports.stopRecording.subscribe(function() {
        stopRecording();
    });

    app.ports.goToStream.subscribe(function(attr) {
        goToStream(attr[0], attr[1]);
    });

}
