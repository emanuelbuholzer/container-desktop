from mitmproxy import http, proxy

class ReverseProxy:
    def __init__(self):
        self.backends = {
            '/api': {"host": 'localhost', "port": 3001},
            '/test': {"host": 'localhost', "port": 3002}
        }

    def request(self, flow: http.HTTPFlow) -> None:
        path_segments = flow.request.path.split('/')
        if len(path_segments) > 1:
            first_segment = '/' + path_segments[1]
            if first_segment in self.backends:
                backend = self.backends[first_segment]
                flow.request.host = backend["host"]
                flow.request.port = backend["port"]
                flow.request.path = flow.request.path.replace(first_segment, "", 1)
                if flow.request.path == "":
                    flow.request.path = "/"

addons = [
    ReverseProxy()
]
