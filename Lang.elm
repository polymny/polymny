module Main exposing (activateFade, activateKeying, addSlide, bindingWebcam, bottomLeft, bottomRight, cancelProduction, cancelPublication, cantUseVideoBecauseAudioOnly, cantUseVideoBecauseNoRecord, chooseProject, clickHereToGoBackHome, close, commit, copyVideoUrl, createGrain, createNewProject, currentPassword, currentProducedVideo, custom, dashboard, deleteAccount, deleteExtraResource, deleteSelf, deleteUserConfirm, detectingDevices, diskUsage, dndWillBreak, downloadVideo, driveSpace, enterNewNameForCapsule, enterPasswords, error, error404, errorBindingWebcam, errorDetectingDevices, errorSharingCapsule, errorUploadingPdf, explainPrivate, explainPrivateWarning, explainPublic, explainUnlisted, exportCapsule, fullscreen, grain, insertNumber, invertSlideAndPrompt, inviteUser, key, keyColor, large, lastModified, loading, medium, next, nextSentence, noProjectsYet, notFound, opacity, pdfConvertFailed, people, playRecord, prev, privacy, privacySettings, produceGosVideo, produceVideo, producing, promptSubtitles, publish, publishVideo, publishing, recordGos, recordingStopped, records, recordsWillBeLost, refreshDevices, replaceSlide, replaceSlideOrAddExternalResource, selectPdf, settings, share, shareCapsuleWith, shortcuts, small, source, spaceUsed, startRecordSentence, topLeft, topRight, transcoding, unpublishVideo, uploadRecord, uploadRecordFailed, uploading, useVideo, usernameOrEmail, users, version, videoNotProduced, videoSettings, watchGosVideo, watchRecord, watchVideo, webcamAnchor, webcamSize, welcomeOnPolymny, whichPage)


recordingStopped : Lang -> String
recordingStopped lang =
    case lang of
        FrFr ->
            "Enregistrement arrété"

        _ ->
            "Recording stopped"


invertSlideAndPrompt : Lang -> String
invertSlideAndPrompt lang =
    case lang of
        FrFr ->
            "Inverser le slide et le prompteur"

        _ ->
            "Invert slide and prompt"


version : Lang -> String
version lang =
    case lang of
        FrFr ->
            "Version"

        _ ->
            "Version"


commit : Lang -> String
commit lang =
    case lang of
        FrFr ->
            "Commit"

        _ ->
            "Commit"


source : Lang -> String
source lang =
    case lang of
        FrFr ->
            "Source"

        _ ->
            "Source"


settings : Lang -> String
settings lang =
    case lang of
        FrFr ->
            "Paramètres"

        _ ->
            "Settings"


records : Lang -> String
records lang =
    case lang of
        FrFr ->
            "Enregistrements"

        _ ->
            "Records"


playRecord : Lang -> String
playRecord lang =
    case lang of
        FrFr ->
            "Jouer l'enregistrement"

        _ ->
            "Play record"


dndWillBreak : Lang -> String
dndWillBreak lang =
    case lang of
        FrFr ->
            "Ce déplacement va détruire certains de vos enregistrements. Êtes-vous sûr de vouloir poursuivre ?"

        _ ->
            "This change will destroy some of your records. Are you sure you want to proceed?"


uploadRecord : Lang -> String
uploadRecord lang =
    case lang of
        FrFr ->
            "Valider cet enregistrement"

        _ ->
            "Validate this record"


recordGos : Lang -> String
recordGos lang =
    case lang of
        FrFr ->
            "Enregistrer ce groupe de slides"

        _ ->
            "Record this group of slides"


watchRecord : Lang -> String
watchRecord lang =
    case lang of
        FrFr ->
            "Regarder cet enregistrement"

        _ ->
            "Watch this record"


welcomeOnPolymny : Lang -> String
welcomeOnPolymny lang =
    case lang of
        FrFr ->
            "Bienvenue sur Polymny !"

        _ ->
            "Welcome on Polymny!"


noProjectsYet : Lang -> String
noProjectsYet lang =
    case lang of
        FrFr ->
            "On dirait que vous n'avez encore aucun projet..."

        _ ->
            "It looks like you have no project yet..."


startRecordSentence : Lang -> String
startRecordSentence lang =
    case lang of
        FrFr ->
            "Pour commencer un enregistrement, il faut choisir une présentation au format PDF sur votre machine."

        _ ->
            "To start recording, you need to choose a PDF slides from your computer."


nextSentence : Lang -> String
nextSentence lang =
    case lang of
        FrFr ->
            "Par exemple, un export PDF de Microsoft PowerPoint ou LibreOffice Impress en paysage au format HD. Une fois la présentation téléchargée, l'enregistrement vidéo des planches pourra débuter."

        _ ->
            "For example, a PDF export version of Microsoft PowerPoint or LibreOffice Impress in HD format. Once the slides have been uploaded, the recording can start."


selectPdf : Lang -> String
selectPdf lang =
    case lang of
        FrFr ->
            "Choisir un fichier PDF"

        _ ->
            "Select a PDF file"


replaceSlideOrAddExternalResource : Lang -> String
replaceSlideOrAddExternalResource lang =
    case lang of
        FrFr ->
            "Remplacer le slide / ajouter une resource externe"

        _ ->
            "Replace slide / add external resource"


replaceSlide : Lang -> String
replaceSlide lang =
    case lang of
        FrFr ->
            "Remplacer un slide"

        _ ->
            "Replace slide"


whichPage : Lang -> String
whichPage lang =
    case lang of
        FrFr ->
            "Quelle page du PDF voulez-vous utiliser ?"

        _ ->
            "Which PDF page do you want to use?"


insertNumber : Lang -> String
insertNumber lang =
    case lang of
        FrFr ->
            "Entrez un numéro de slide plus grand que 0"

        _ ->
            "Enter a slide number greater than 0"


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


deleteExtraResource : Lang -> String
deleteExtraResource lang =
    case lang of
        FrFr ->
            "Supprimer la ressource externe"

        _ ->
            "Delete extra resource"


currentPassword : Lang -> String
currentPassword lang =
    case lang of
        FrFr ->
            "Mot de passe actuel"

        _ ->
            "Current password"


useVideo : Lang -> String
useVideo lang =
    case lang of
        FrFr ->
            "Incruster la vidéo"

        _ ->
            "Use webcam video"


webcamSize : Lang -> String
webcamSize lang =
    case lang of
        FrFr ->
            "Taille de la webcam"

        _ ->
            "Webcam size"


small : Lang -> String
small lang =
    case lang of
        FrFr ->
            "Petite"

        _ ->
            "Small"


medium : Lang -> String
medium lang =
    case lang of
        FrFr ->
            "Moyenne"

        _ ->
            "Medium"


large : Lang -> String
large lang =
    case lang of
        FrFr ->
            "Grosse"

        _ ->
            "Large"


webcamAnchor : Lang -> String
webcamAnchor lang =
    case lang of
        FrFr ->
            "Position de la webcam"

        _ ->
            "Webcam position"


topLeft : Lang -> String
topLeft lang =
    case lang of
        FrFr ->
            "En haut à gauche"

        _ ->
            "Top-left corner"


topRight : Lang -> String
topRight lang =
    case lang of
        FrFr ->
            "En haut à droite"

        _ ->
            "Top-right corner"


bottomLeft : Lang -> String
bottomLeft lang =
    case lang of
        FrFr ->
            "En bas à gauche"

        _ ->
            "Bottom-left corner"


bottomRight : Lang -> String
bottomRight lang =
    case lang of
        FrFr ->
            "En bas à droite"

        _ ->
            "Bottom-right corner"


lastModified : Lang -> String
lastModified lang =
    case lang of
        FrFr ->
            "Dernière modification"

        _ ->
            "Last modified"


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


produceVideo : Lang -> String
produceVideo lang =
    case lang of
        FrFr ->
            "Produire la vidéo"

        _ ->
            "Produce video"


produceGosVideo : Lang -> String -> String
produceGosVideo lang gos =
    case lang of
        FrFr ->
            "Produire le grain " ++ gos

        _ ->
            "Produce grain " ++ gos


publish : Lang -> String
publish lang =
    case lang of
        FrFr ->
            "Publier"

        _ ->
            "Publish"


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


publishVideo : Lang -> String
publishVideo lang =
    case lang of
        FrFr ->
            "Publier la vidéo"

        _ ->
            "Publish video"


watchVideo : Lang -> String
watchVideo lang =
    case lang of
        FrFr ->
            "Voir la vidéo"

        _ ->
            "Watch video"


watchGosVideo : Lang -> String -> String
watchGosVideo lang gos =
    case lang of
        FrFr ->
            "Voir le grain " ++ gos

        _ ->
            "Watch grain " ++ gos


producing : Lang -> String
producing lang =
    case lang of
        FrFr ->
            "Production de la vidéo en cours..."

        _ ->
            "Producing video..."


publishing : Lang -> String
publishing lang =
    case lang of
        FrFr ->
            "Publication de la vidéo en cours..."

        _ ->
            "Publishing video..."


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


videoSettings : Lang -> String
videoSettings lang =
    case lang of
        FrFr ->
            "Paramètres de la vidéo"

        _ ->
            "Video settings"


privacy : Lang -> Capsule.Privacy -> String
privacy lang p =
    case p of
        Capsule.Private ->
            case lang of
                FrFr ->
                    "privée"

                _ ->
                    "private"

        Capsule.Unlisted ->
            case lang of
                FrFr ->
                    "non répertoriée"

                _ ->
                    "unlisted"

        Capsule.Public ->
            case lang of
                FrFr ->
                    "publique"

                _ ->
                    "public"


privacySettings : Lang -> String
privacySettings lang =
    case lang of
        FrFr ->
            "Paramètres de confidentialité"

        _ ->
            "Privacy settings"


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


addSlide : Lang -> String
addSlide lang =
    case lang of
        FrFr ->
            "Ajouter un slide"

        _ ->
            "Add a slide"


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


cancelProduction : Lang -> String
cancelProduction lang =
    case lang of
        FrFr ->
            "Annuler la production"

        _ ->
            "Cancel production"


cancelPublication : Lang -> String
cancelPublication lang =
    case lang of
        FrFr ->
            "Annuler la publication"

        _ ->
            "Cancel publication"


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


usernameOrEmail : Lang -> String
usernameOrEmail lang =
    case lang of
        FrFr ->
            "Nom d'utilisateur ou adresse e-mail"

        _ ->
            "Username or email address"


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


clickHereToGoBackHome : Lang -> String
clickHereToGoBackHome lang =
    case lang of
        FrFr ->
            "Cliquez ici pour retourner à l'accueil."

        _ ->
            "Click here to go back to the home page."


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


prev : Lang -> String
prev lang =
    case lang of
        FrFr ->
            "Précédent"

        _ ->
            "Previous"


next : Lang -> String
next lang =
    case lang of
        FrFr ->
            "suivant"

        _ ->
            "Next"


promptSubtitles : Lang -> String
promptSubtitles lang =
    case lang of
        FrFr ->
            "Utiliser le prompteur pour générer les sous-titres"

        _ ->
            "Use prompt text to generate subtitles"


unpublishVideo : Lang -> String
unpublishVideo lang =
    case lang of
        FrFr ->
            "Dépublier la vidéo"

        _ ->
            "Unpublish video"


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


deleteUserConfirm : Lang -> String -> String -> String
deleteUserConfirm lang name email =
    case lang of
        FrFr ->
            "Voulez-vous vraiment supprimer l'utilisateur\n " ++ name ++ "<" ++ email ++ "> ?"

        _ ->
            "Do you really want to delete user\n " ++ name ++ "<" ++ email ++ "> ?"


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


error : Lang -> String
error lang =
    case lang of
        FrFr ->
            "Erreur"

        _ ->
            "Error"


key : Lang -> String
key lang =
    case lang of
        FrFr ->
            "Key"

        _ ->
            "Key"


keyColor : Lang -> String
keyColor lang =
    case lang of
        FrFr ->
            "Couleur de keying"

        _ ->
            "Keying color"


activateKeying : Lang -> String
activateKeying lang =
    case lang of
        FrFr ->
            "Activer le keying"

        _ ->
            "Activate keying"


activateFade : Lang -> String
activateFade lang =
    case lang of
        FrFr ->
            "Activer le fading"

        _ ->
            "Activate fading"


errorUploadingPdf : Lang -> String
errorUploadingPdf lang =
    case lang of
        FrFr ->
            "Une erreur est survenue lors de l'envoi du PDF."

        _ ->
            "An error occured while uploading the PDF."


grain : Lang -> String
grain lang =
    case lang of
        FrFr ->
            "Grain"

        _ ->
            "Grain"


custom : Lang -> String
custom lang =
    case lang of
        FrFr ->
            "Personnalisé"

        _ ->
            "Custom"


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


recordsWillBeLost : Lang -> String
recordsWillBeLost lang =
    case lang of
        FrFr ->
            "Les enregistrements non validés seront perdus."

        _ ->
            "Non validated records will be lost."


explainPrivate : Lang -> String
explainPrivate lang =
    case lang of
        FrFr ->
            "la vidéo ne sera visible que par les utilisateurs explicitement autorisées"

        _ ->
            "the video will be visible only by explicitly authorized users"


explainPrivateWarning : Lang -> String
explainPrivateWarning lang =
    case lang of
        FrFr ->
            "cette fonctionnalité n'est pas encore prête : aucun utilisateur ne pourra voir la vidéo à part vous-même"

        _ ->
            "this feature is not ready yet: no users except you will be able to watch the video"


explainUnlisted : Lang -> String
explainUnlisted lang =
    case lang of
        FrFr ->
            "la vidéo ne sera visible que par les personnes connaissant l'URL, Polymny Studio ne partagera pas l'URL de la vidéo"

        _ ->
            "the video will be visible by anyone who knows the URL, Polymny Studio will not share the video's URL"


explainPublic : Lang -> String
explainPublic lang =
    case lang of
        FrFr ->
            "la vidéo sera visible par les personnes connaissant l'URL, Polymny Studio pourrait, dans le futur, partager l'URL de la vidéo via un moteur de recherche, un système de recommandations, etc."

        _ ->
            "the video will be visible by anyone who knows the URL, Polymny Studio may, in the future, share the video's URL via a search engine, a recommendation system, etc."


close : Lang -> String
close lang =
    case lang of
        FrFr ->
            "Fermer"

        _ ->
            "Close"


createGrain : Lang -> String
createGrain lang =
    case lang of
        FrFr ->
            "Créer un grain"

        _ ->
            "Create grain"
