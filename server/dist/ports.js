function setupPorts(app) {

    var stream = null,
        bindingWebcam = false,
        unbindRequested = false,
        recorder,
        recording,
        currentEvents,
        nextSlideCallbacks = [];

    var socket;
    if (flags.user) {
        initWebsocket();
    }

    function initWebsocket() {
        socket = new WebSocket(flags.global.socket_root);

        socket.onmessage = function(event) {
            console.log(event.data);
            app.ports.websocketMsg.send(JSON.parse(event.data));
        }

        socket.onopen = function() {
            socket.send(flags.user.cookie);
        }

        socket.onclose = function() {
            // Reconnect if connection is lost
            setTimeout(initWebsocket, 1000);
        }
    }

    function subscribe(object, fun) {
        if (object !== undefined) {
            object.subscribe(fun);
        }
    }

    function setLanguage(arg) {
        localStorage.setItem('language', arg);
    }

    function setZoomLevel(arg) {
        localStorage.setItem('zoomLevel', arg);
    }

    function setAcquisitionInverted(arg) {
        localStorage.setItem('acquisitionInverted', arg);
    }

    function setVideoDeviceId(arg) {
        localStorage.setItem('videoDeviceId', arg);
    }

    function setResolution(arg) {
        localStorage.setItem('resolution', arg);
    }

    function setAudioDeviceId(arg) {
        localStorage.setItem('audioDeviceId', arg);
    }

    function setSortBy(arg) {
        localStorage.setItem('sortBy', JSON.stringify(arg));
    }

    async function findDevices(force) {

        let inputs = localStorage.getItem('devices');

        if (inputs !== null && !force) {
            console.log("Detecting devices from cache");
            app.ports.devicesReceived.send(JSON.parse(inputs));
            return;
        }

        console.log("Detecting devices");

        // Ask user media to ask permission so we can read labels later.
        try {
            stream = await navigator.mediaDevices.getUserMedia({video: true, audio: true});
        } catch (e) {
            try {
                stream = await navigator.mediaDevices.getUserMedia({video: false, audio: true});
            } catch(e) {
                app.ports.deviceDetectionFailed.send(null);
                return;
            }
        }

        await unbindWebcam();

        let devices = await navigator.mediaDevices.enumerateDevices();
        inputs = {
            video: [],
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
                        stream = await navigator.mediaDevices.getUserMedia(options);
                        await unbindWebcam();
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

        localStorage.setItem('devices', JSON.stringify(inputs));
        app.ports.devicesReceived.send(inputs);
    }

    async function bindWebcam(args) {
        let cameraOptions = args[0];
        let recorderOptions = args[1];

        if (unbindRequested) {
            unbindRequested = false;
        }

        if (bindingWebcam) {
            return;
        }

        // Unbound webcam before rebinding it.
        if (stream !== null) {
            await unbindWebcam();
        }

        console.log("Binding webcam");
        bindingWebcam = true;
        try {
            stream = await navigator.mediaDevices.getUserMedia(cameraOptions);
        } catch (e) {
            app.ports.bindingWebcamFailed.send(null);
            return;
        }

        if (unbindRequested) {
            await unbindWebcam();
        }

        await playWebcam();

        recorder = new MediaRecorder(stream, recorderOptions);
        recorder.ondataavailable = (data) => {
            app.ports.recordArrived.send({
                blob: data.data,
                events: currentEvents,
            });
        };
        recorder.onerror = (err) => {
            console.log(err);
        };

        bindingWebcam = false;

        console.log("Webcam bound");
        app.ports.webcamBound.send(null);
    }

    async function unbindWebcam() {
        if (stream === null || bindingWebcam) {
            unbindRequested = true;
            return
        }

        console.log("Unbinding webcam");
        stream.getTracks().forEach(function(track) {
            track.stop();
        });
        stream = null;
    }

    async function playWebcam() {
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
        element.muted = true;
        element.play();
    }

    async function playRecord(record) {
        let video = document.getElementById(videoId);
        video.srcObject = null;

        if (typeof record.blob === "string" || record.blob instanceof String) {
            video.src = record.blob;
        } else {
            video.src = URL.createObjectURL(record.blob);
        }

        video.muted = false;

        video.onended = () => {
            playWebcam();
            let extra = document.getElementById('extra');
            if (extra instanceof HTMLVideoElement) {
                extra.pause();
                extra.currentTime = 0;
            }
            app.ports.playRecordFinished.send(null);
        };

        // Skip last transition which is the end of the video.
        for (let i = 0; i < record.events.length - 1; i++) {
            let event = record.events[i];
            let callback;
            switch (event.ty) {
                case "next_slide":
                    callback = () => app.ports.nextSlideReceived.send(null);
                    break;
                case "play":
                    callback = () => {
                        let extra = document.getElementById('extra');
                        extra.muted = true;
                        extra.currentTime = 0;
                        extra.play();
                    };
                    break;
                case "stop":
                    callback = () => {
                        let extra = document.getElementById('extra');
                        extra.currentTime = 0;
                        extra.stop();
                    };
                    break;
            }

            if (callback !== undefined) {
                nextSlideCallbacks.push(setTimeout(callback, event.time));
            }
        }

        video.play();
    }

    function startRecording() {
        if (recorder !== undefined && !recording) {
            recording = true;
            recorder.start();
            currentEvents = [{
                time: Math.round(window.performance.now()),
                ty: "start"
            }];
            let extra = document.getElementById('extra');
            if (extra instanceof HTMLVideoElement) {
                extra.muted = true;
                extra.currentTime = 0;
                extra.play();
                currentEvents.push({
                    time: 0,
                    ty: "play"
                });
            }
        }
    }

    function stopRecording() {
        if (recording) {
            let time = Math.round(window.performance.now()) - currentEvents[0].time;

            let extra = document.getElementById('extra');
            if (extra instanceof HTMLVideoElement) {
                extra.muted = true;
                extra.pause();
                extra.currentTime = 0;
                currentEvents.push({
                    ty: "stop",
                    time: time
                });
            }

            currentEvents.push({
                time: time,
                ty: "end",
            });

            currentEvents[0].time = 0;
            recorder.stop();
            recording = false;
        }
    }

    function uploadRecord(args) {
        let capsuleId = args[0];
        let gos = args[1];
        let record = args[2];

        if (typeof record.blob === "string" || record.blob instanceof String) {

            // User wants to validate the old record, don't need to do anything,
            // just send the message to let them know it's done
            app.ports.capsuleUpdated.send(null);

        } else {

            let xhr = new XMLHttpRequest();
            xhr.open("POST", "/api/upload-record/" + capsuleId + "/" + gos, true);

            xhr.upload.onprogress = (e) => {
                app.ports.progressReceived.send(e.loaded / e.total);
            };

            xhr.onreadystatechange = () => {
                if (xhr.readyState === 4) {
                    if (xhr.status === 200) {
                        let capsule = JSON.parse(xhr.responseText);
                        capsule.structure[gos].events = record.events;

                        let xhr2 = new XMLHttpRequest();
                        xhr2.open("POST", "/api/update-capsule/", true);

                        xhr2.onreadystatechange = () => {
                            if (xhr2.readyState === 4) {
                                if (xhr2.status === 200) {
                                    app.ports.capsuleUpdated.send(capsule);
                                } else {
                                    app.ports.uploadRecordFailed.send(null);
                                }
                            };
                        }

                        xhr2.send(JSON.stringify(capsule));
                    } else {
                        app.ports.uploadRecordFailed.send(null);
                    }
                }
            }

            xhr.send(record.blob);
        }
    }

    function askNextSlide() {
        currentEvents.push({
            time: Math.round(window.performance.now()) - currentEvents[0].time,
            ty: "next_slide"
        });
    }

    function askNextSentence() {
        currentEvents.push({
            time: Math.round(window.performance.now()) - currentEvents[0].time,
            ty: "next_sentence"
        });
    }

    async function exportCapsule(capsule) {
        let zip = new JSZip();

        for (let gosIndex = 0; gosIndex < capsule.structure.length; gosIndex++) {

            let gos = capsule.structure[gosIndex];
            let gosDir = zip.folder(gosIndex + 1);

            for (let slideIndex  = 0; slideIndex < gos.slides.length; slideIndex++) {
                let slide = gos.slides[slideIndex];

                let resp = await fetch("/data/" + capsule.id + "/assets/" + slide.uuid + ".png");
                let blob = await resp.blob();

                gosDir.file((slideIndex + 1) + ".png", blob);

                slide.uuid = (gosIndex + 1) + "/" + (slideIndex + 1) + ".png";

                if (slide.extra != undefined) {
                    let resp = await fetch("/data/" + capsule.id + "/assets/" + slide.extra + ".mp4");
                    let blob = await resp.blob();

                    gosDir.file((slideIndex + 1) + ".mp4", blob);
                    slide.extra = (gosIndex + 1) + "/" + (slideIndex + 1) + ".mp4";
                }


            }

            if (gos.record != undefined) {
                let resp = await fetch("/data/" + capsule.id + "/assets/" + gos.record.uuid + ".webm");
                let blob = await resp.blob();

                gosDir.file("record.webm", blob);
                gos.record = (gosIndex + 1) + "/record.webm";
            }

        }

        if (capsule.produced) {
            let resp = await fetch("/data/" + capsule.id + "/output.mp4");
            let blob = await resp.blob();
            zip.file("output.mp4", blob);
        }

        zip.file("structure.json", JSON.stringify(capsule, null, 4));

        let content = await zip.generateAsync({type: "blob"},
            function updateCallback(metadata) {
                console.log("progression: " + metadata.percent.toFixed(2) + " %");
                if(metadata.currentFile) {
                    console.log("current file = " + metadata.currentFile);
                }
            }
        );

        saveAs(content, capsule.id + ".zip");
    }

    async function importCapsule(args) {
        let project = args[0];
        let capsule = args[1];

        let zip = new JSZip();
        let content = await zip.loadAsync(capsule);
        console.log(content);
        let structure = JSON.parse(await content.file("structure.json").async("string"));

        // Creates the empty capsule.
        let resp = await fetch("/api/empty-capsule/" + project + "/" + structure.name + " (copie)", {method: "POST"});
        let json = await resp.json();

        structure.id = json.id;

        // Upload the slides.
        for (let gosIndex = 0; gosIndex < structure.structure.length; gosIndex++) {
            let gos = structure.structure[gosIndex];

            for (let slideIndex = 0; slideIndex < gos.slides.length; slideIndex++) {
                let slide = gos.slides[slideIndex];
                let image = await content.file(slide.uuid).async("blob");
                image = image.slice(0, image.size, "image/png")

                // Upload the slide.
                let resp = await fetch("/api/add-slide/" + json.id + "/-1/-1", {method: "POST", body: image});
                resp = await resp.json();

                // Find uuid of the slide we added.
                let newGos = resp.structure[resp.structure.length - 1];
                let newSlide = newGos.slides[newGos.slides.length - 1];

                slide.uuid = newSlide.uuid;
            }

        }

        // Set the correct structure.
        // Remove records because they are currently null.
        let structureClone = JSON.parse(JSON.stringify(structure));
        for (let gos of structureClone.structure) {
            gos.record = null;
            for (let slide of gos.slides) {
                slide.extra = null;
            }
        }

        // Remove from json attributes that the server doesn't want.
        delete structureClone.produced;

        await fetch("/api/update-capsule/", {
            method: "POST",
            body: JSON.stringify(structureClone),
            headers: {"Content-Type": "application/json"},
        });

        resp = undefined;

        // Upload the records and extra
        for (let gosIndex = 0; gosIndex < structure.structure.length; gosIndex++) {
            let gos = structure.structure[gosIndex];

            // Upload the gos record if any.
            if (gos.record !== null) {
                let blob = await content.file(gos.record).async("blob");
                blob = blob.slice(0, blob.size, "video/webm");
                resp = await fetch("/api/upload-record/" + json.id + "/" + gosIndex, {method: "POST", body: blob});
            }

            for (let slideIndex = 0; slideIndex < gos.slides.length; slideIndex++) {
                let slide = gos.slides[slideIndex];
                if (slide.extra !== null) {
                    let blob = await content.file(slide.extra).async("blob");
                    blob = blob.slice(0, blob.size, "video/mp4");
                    resp = await fetch("/api/replace-slide/" + json.id + "/" + slide.uuid + "/-1", {method: "POST", body: blob});

                }
            }
        }

        // let lastStructure = resp !== undefined ? await resp.json() : structureClone;
        // app.ports.capsuleUpdated.send(lastStructure);

    }

    function copyString(str) {
        let el = document.createElement('textarea');
        el.value = str;
        el.setAttribute('readonly', '');
        el.style = {position: 'absolute', left: '-9999px'};
        document.body.appendChild(el);
        el.select();
        document.execCommand('copy');
        document.body.removeChild(el);
    }

    function scrollIntoView(anchor) {
        let element = document.getElementById(anchor);
        if (element !== null) {
            element.scrollIntoView();
        }
    }

    function select(args) {
        let project = args[0];
        let mimes = args[1];
        let input = document.createElement('input');
        input.type = 'file';
        input.accept = mimes.join(',');
        input.onchange = function(e) {
            app.ports.selected.send([project, e.target.files[0]]);
        };
        input.click();
    }

    function setPointerCapture(args) {
        let id = args[0];
        let pointerId = args[1];
        let element = document.getElementById(id);
        if (element === null) {
            console.error("Cannot set pointer capture of null element");
            return;
        }

        element.setPointerCapture(pointerId);
    }

    subscribe(app.ports.setLanguage, setLanguage);
    subscribe(app.ports.setZoomLevel, setZoomLevel);
    subscribe(app.ports.setAcquisitionInverted, setAcquisitionInverted);
    subscribe(app.ports.setVideoDeviceId, setVideoDeviceId);
    subscribe(app.ports.setResolution, setResolution);
    subscribe(app.ports.setAudioDeviceId, setAudioDeviceId);
    subscribe(app.ports.setSortBy, setSortBy);
    subscribe(app.ports.findDevices, findDevices);
    subscribe(app.ports.playWebcam, playWebcam);
    subscribe(app.ports.bindWebcam, bindWebcam);
    subscribe(app.ports.unbindWebcam, unbindWebcam);
    subscribe(app.ports.startRecording, startRecording);
    subscribe(app.ports.stopRecording, stopRecording);
    subscribe(app.ports.playRecord, playRecord);
    subscribe(app.ports.askNextSlide, askNextSlide);
    subscribe(app.ports.askNextSentence, askNextSentence);
    subscribe(app.ports.uploadRecord, uploadRecord);
    subscribe(app.ports.copyString, copyString);
    subscribe(app.ports.scrollIntoView, scrollIntoView);
    subscribe(app.ports.exportCapsule, exportCapsule);
    subscribe(app.ports.importCapsule, importCapsule);
    subscribe(app.ports.select, select);
    subscribe(app.ports.setPointerCapture, setPointerCapture);

    const quickScan = [
        { "width": 3840, "height": 2160 }, { "width": 1920, "height": 1080 }, { "width": 1600, "height": 1200 },
        { "width": 1280, "height":  720 }, { "width":  800, "height":  600 }, { "width":  640, "height":  480 },
        { "width":  640, "height":  360 }, { "width":  352, "height":  288 }, { "width":  320, "height":  240 },
        { "width":  176, "height":  144 }, { "width":  160, "height":  120 }
    ];

    const videoId = "video";
}
