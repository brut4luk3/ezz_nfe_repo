param([ValidateSet("dev","prod","all")][string]$Env="all")
Set-Location (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

switch ($Env) {
  "dev"  { flutterfire configure -p ezz-nfe-dev  -o lib/firebase_options_dev.dart  -a com.lucas.ezznfe.dev  --android-out=android/app/src/dev/google-services.json  --platforms=android -y }
  "prod" { flutterfire configure -p ezz-nfe-prod -o lib/firebase_options_prod.dart -a com.lucas.ezznfe --android-out=android/app/src/prod/google-services.json --platforms=android -y }
  "all"  { & $PSScriptRoot\flutterfire_config.ps1 dev; & $PSScriptRoot\flutterfire_config.ps1 prod }
}