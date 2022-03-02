module Main exposing (bindingWebcam, cantUseVideoBecauseAudioOnly, cantUseVideoBecauseNoRecord, chooseProject, copyVideoUrl, createNewProject, currentProducedVideo, dashboard, deleteAccount, deleteSelf, detectingDevices, diskUsage, downloadVideo, driveSpace, enterNewNameForCapsule, enterPasswords, error404, errorBindingWebcam, errorDetectingDevices, errorSharingCapsule, errorUploadingPdf, exportCapsule, fullscreen, inviteUser, loading, notFound, opacity, pdfConvertFailed, people, promptSubtitles, refreshDevices, share, shareCapsuleWith, shortcuts, spaceUsed, transcoding, uploadRecordFailed, uploading, users, videoNotProduced)


loading : Lang -> String
loading lang =
    case lang of
        FrFr ->
            "Chargement"

        _ ->
            "Loading"


uploading : Lang -> String
uploading lang =
    case lang of
        FrFr ->
            "Envoi en cours, veuillez patienter..."

        _ ->
            "Upload in progress, please wait..."


transcoding : Lang -> String
transcoding lang =
    case lang of
        FrFr ->
            "Transcodage du fichier vidéo, veuillez patienter..."

        _ ->
            "Video transcoding, please wait..."


diskUsage : Lang -> String
diskUsage lang =
    case lang of
        FrFr ->
            "Taille (MiB)"

        _ ->
            "Size (MiB)"


driveSpace : Lang -> String
driveSpace lang =
    case lang of
        FrFr ->
            "Espace de stockage"

        _ ->
            "Drive space"


spaceUsed : Lang -> String -> String -> String
spaceUsed lang used max =
    case lang of
        FrFr ->
            used ++ " Go utilsés sur " ++ max ++ " Go"

        _ ->
            used ++ " GB used on " ++ max ++ " GB"


currentProducedVideo : Lang -> String
currentProducedVideo lang =
    case lang of
        FrFr ->
            "Vidéo produite actuelle"

        _ ->
            "Current produced video"


videoNotProduced : Lang -> String
videoNotProduced lang =
    case lang of
        FrFr ->
            "La vidéo n'a pas encore été produite"

        _ ->
            "Video has not been produced yet"


downloadVideo : Lang -> String
downloadVideo lang =
    case lang of
        FrFr ->
            "Télécharger la vidéo"

        _ ->
            "Download video"


copyVideoUrl : Lang -> String
copyVideoUrl lang =
    case lang of
        FrFr ->
            "Copier l'URL de la vidéo"

        _ ->
            "Copy video URL"


fullscreen : Lang -> String
fullscreen lang =
    case lang of
        FrFr ->
            "Plein écran"

        _ ->
            "Fullscreen"


opacity : Lang -> String
opacity lang =
    case lang of
        FrFr ->
            "Opacité"

        _ ->
            "Opacity"


refreshDevices : Lang -> String
refreshDevices lang =
    case lang of
        FrFr ->
            "Raffraichir la liste des périphériques"

        _ ->
            "Refresh device list"


pdfConvertFailed : Lang -> String
pdfConvertFailed lang =
    case lang of
        FrFr ->
            "Une erreur est survenue. Le numéro de page est-il correct ?"

        _ ->
            "An error happend. Is the page number correct?"


detectingDevices : Lang -> String
detectingDevices lang =
    case lang of
        FrFr ->
            "Détection des périphériques en cours..."

        _ ->
            "Detecting devices..."


bindingWebcam : Lang -> String
bindingWebcam lang =
    case lang of
        FrFr ->
            "Connection aux périphériques en cours..."

        _ ->
            "Connecting to devices..."


errorDetectingDevices : Lang -> String
errorDetectingDevices lang =
    case lang of
        FrFr ->
            "Erreur lors de la détection les périphériques. La webcam et le micro sont-ils bien autorisés ?"

        _ ->
            "Error while detecting devices. Are webcam and microphone allowed ?"


errorBindingWebcam : Lang -> String
errorBindingWebcam lang =
    case lang of
        FrFr ->
            "Erreur lors de la connexion aux périphériques. La webcam est-elle utilisée par un autre logiciel ?"

        _ ->
            "Error while connecting to devices. Is the webcam used by some other software?"


cantUseVideoBecauseNoRecord : Lang -> String
cantUseVideoBecauseNoRecord lang =
    case lang of
        FrFr ->
            "Vous ne pouvez pas incruster la vidéo car il n'y a aucun enregistrement pour ce groupe de slides."

        _ ->
            "You cannot use webcam video because there is no record for this group of slides."


cantUseVideoBecauseAudioOnly : Lang -> String
cantUseVideoBecauseAudioOnly lang =
    case lang of
        FrFr ->
            "Vous ne pouvez pas incruster la vidéo car l'enregistrement ne contient que de l'audio."

        _ ->
            "You cannot use webcam video because the record contains only audio."


exportCapsule : Lang -> String
exportCapsule lang =
    case lang of
        FrFr ->
            "Exporter la capsule"

        _ ->
            "Export capsule"


share : Lang -> String
share lang =
    case lang of
        FrFr ->
            "Partager"

        _ ->
            "Share"


shareCapsuleWith : Lang -> String
shareCapsuleWith lang =
    case lang of
        FrFr ->
            "Partager la capsule avec"

        _ ->
            "Share capsule with"


errorSharingCapsule : Lang -> String
errorSharingCapsule lang =
    case lang of
        FrFr ->
            "Erreur lors du partage de la capsule : l'utilisateur existe-t-il ?"

        _ ->
            "Error while sharing capsule: does the user exist?"


people : Lang -> String
people lang =
    case lang of
        FrFr ->
            "Collaborateurs"

        _ ->
            "People"


error404 : Lang -> String
error404 lang =
    case lang of
        FrFr ->
            "Erreur 404"

        _ ->
            "Error 404"


notFound : Lang -> String
notFound lang =
    case lang of
        FrFr ->
            "La page que vous demandez n'as pas été trouvée."

        _ ->
            "The page you requested was not found."


dashboard : Lang -> String
dashboard lang =
    case lang of
        FrFr ->
            "Synthèse"

        _ ->
            "Dashboard"


users : Lang -> String
users lang =
    case lang of
        FrFr ->
            "Utilisateurs"

        _ ->
            "Users"


promptSubtitles : Lang -> String
promptSubtitles lang =
    case lang of
        FrFr ->
            "Utiliser le prompteur pour générer les sous-titres"

        _ ->
            "Use prompt text to generate subtitles"


shortcuts : Lang -> List String
shortcuts lang =
    case lang of
        FrFr ->
            [ "Enregistrer : espace"
            , "Finir l'enregistrement : espace"
            , "Suite : flèche à droite"
            ]

        _ ->
            [ "Record: space"
            , "End record: space"
            , "Next: Right arrow"
            ]


inviteUser : Lang -> String
inviteUser lang =
    case lang of
        FrFr ->
            "Inviter un utilisateur"

        _ ->
            "Invite a User"


enterPasswords : Lang -> String
enterPasswords lang =
    case lang of
        FrFr ->
            "Saisir un mot de passe pour valider l'inscritption à Polymny studio"

        _ ->
            "Enter a password to validate Polymny studio invitation"


deleteSelf : Lang -> String
deleteSelf lang =
    case lang of
        FrFr ->
            "Vous allez supprimer votre compte. Toutes vos capsules seront supprimées, et les vidéos publiées ne seront plus accessibles. Voulez-vous vraiment continuer ?"

        _ ->
            "You are going to delete your account. All your capsules will be deleted, and the published videos will no longer be accessible. Are you sure you want to continue?"


deleteAccount : Lang -> String
deleteAccount lang =
    case lang of
        FrFr ->
            "Supprimer le compte"

        _ ->
            "Delete the account"


uploadRecordFailed : Lang -> String
uploadRecordFailed lang =
    case lang of
        FrFr ->
            "Échec de l'envoi de l'enregistrement, veuillez recommencer."

        _ ->
            "Record upload failed, please try again."


errorUploadingPdf : Lang -> String
errorUploadingPdf lang =
    case lang of
        FrFr ->
            "Une erreur est survenue lors de l'envoi du PDF."

        _ ->
            "An error occured while uploading the PDF."


enterNewNameForCapsule : Lang -> String
enterNewNameForCapsule lang =
    case lang of
        FrFr ->
            "Entrez le nouveau nom de la capsule"

        _ ->
            "Enter the new name for the capsule"


createNewProject : Lang -> String
createNewProject lang =
    case lang of
        FrFr ->
            "Créer un nouveau projet"

        _ ->
            "Create new project"


chooseProject : Lang -> String
chooseProject lang =
    case lang of
        FrFr ->
            "Choisir le project"

        _ ->
            "Choose project"
