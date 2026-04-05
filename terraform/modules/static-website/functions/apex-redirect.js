async function handler(event) {
    const request = event.request;
    const uri = request.uri;

    // Check whether the URI is missing a file name.
    if (uri.endsWith("/")) {
        request.uri += "index.html";
    }
    // Check whether the URI is missing a file extension.
    else if (!uri.includes(".")) {
        request.uri += "/index.html";
    }

    // Redirect www to apex
    if (request.headers.host) {
        const host = request.headers.host.value;
        if (host.startsWith("www")) {

            // prevent redirect weirdness
            if (request.uri.endsWith("index.html")) {
                request.uri = request.uri.replace(/index\.html+$/, "");
            }

            return {
                statusCode: 301,
                statusDescription: "Moved Permanently",
                headers: {
                    "location": {"value": `https://${host}${request.uri}`}
                }
            };
        }
    }

    return event.request;
}
