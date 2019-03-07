Copy-Item -Path "./mountebank_8080" -Destination "../config/" -Recurse
& "docker" build --rm -t mountebank4mockup-test:latest ../
Remove-Item -Path "../config/mountebank_8080" -Recurse