Copy-Item -Path "./mountebank_8080_MTGIO" -Destination "../config/" -Recurse
& "docker" build --rm -t mountebank4mockup-test:latest ../
Remove-Item -Path "../config/mountebank_8080_MTGIO/" -Recurse