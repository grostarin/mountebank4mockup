# Mountebank4mockup

This project is an utility to build custom mockups server : it should not used as standalone.

It is based on [Mountebank](http://www.mbtest.org/), a restful application : Mountebank's ressources are legion of "imposters"; Each "imposter" aims at simulate or record webservice request/response.

Before building your one container which will host imposters, you have to build your imposters stubs by :

- recording requests/responses (using mountebank4proxy) and reuse records.
- write stub yourselve.

Mockups source code have to be stored in your project (not this one) (see "Imposter's data" paragraph below)

## Imposter's data

Each imposter could have as many stub as needed.

### Directories to save imposters

In your project, you could create as many imposters as needed : one directory by imposer.

Syntax of imposter's directory : mountebank_<IMPOSTER_PORT> (IMPOSTER_PORT : imposter's listening port)

Anywhere in your project (prefer src/mountebank or a specific mountebank plugin), for example :

```bash
cd <YOUR_PROJECT_DIR>/src/mountebank
mkdir mountebank_8080
```

Docker run will listen on port 8080 with imposter data from directory "mountebank_8080".

### Stub's data

NB : Mountebank JSON syntax is rich, take a look at [Contract on Mountebank](http://www.mbtest.org/docs/api/contracts) for details.

#### Predicates / Responses

Put imposter stubs data in directory created in previous step.

Each imposter stub must follow the mountebank syntax of a stub, create as many as necessary stubs "stub_<STUB_NAME>.json" with stub data ("predicates", "responses", ...), example :

```bash
cd <YOUR_PROJECT_DIR>/src/mountebank/mountebank_8080
touch stub_RESSOURCE_NAME.json
```

stub_RESSOURCE_NAME.json content :

```json
{
    "predicates": [
        {
            "startsWith": {
                "path": "/my/path/"
            }
        }
    ],
    "responses": [
        {
            "is": {
                "statusCode": 200,
                "headers": {
                    "Date": "Mon, 25 Feb 2019 17:54:41 GMT",
                    "Content-Type": "application/json; charset=utf-8"
                },
                "body": "{\"key\":\"value\"}"
                "_mode": "text",
                "_proxyResponseTime": 1100
            }
        }
    ]
}
```

This stub responds :

- if request path begins with "/my/path".
- with response defined in "is" json value.

#### Root imposter attributes

To change name, protocol, default response or other root imposter attributes...

Create a "imposter.json", example :

```bash
cd <YOUR_PROJECT_DIR>/src/mountebank/mountebank_8080
touch imposter.json
```

imposter.json content :

```json
{
    "port":8080,
    "protocol": "http",
    "name": "Magic the gathering API proxy",
    "recordRequests": "true",
    "defaultResponse": {
        "statusCode": 404,
        "body": "No response found YOUYOU",
        "headers": {}
    },
    "stubs":[]
}
```

This imposter.json file will be use instead of default one.

## Build

Build your own projet injenkins build with "mountebank4mockup" oney build option.

## Run

Run the image as follows replacing PORT with the port(s) of your imposter(s).

``` bash
docker run --name mountebank --restart always \
-d -p 2525:2525 \
[-p <DOCKER_HOST_PORT>:<IMPOSTER_POST> \]
<IMAGE_NAME>:<IMAGE_TAG>
```

Note that 2525 docker port is the port of Mountbank administration and cannot be changed.

## Dockerfile build process

- uses third party mockups data (stubs of each imposter) in <THIS_PROJECT_DIR>/config (get directories syntax from "Directories to save imposters").
- have to be launch in jenkins via a specfic job with build parameter BUILD_METHOD="MOUNTEBANK"

## Credits

[Mountebank project](https://github.com/bbyars/mountebank)

[Mountebank docker project](https://github.com/andyrbell/mountebank)

[JQ JSON CLI](https://stedolan.github.io/jq/)