/*
Copyright 2018 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package com.anulabs.microservice;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

import java.util.Arrays;
import java.util.List;

@RestController
public class MicroserviceController {

    @Value("${UPSTREAM_URI:https//jsonplaceholder.typicode.com/users/1")
    private String uri;

    @Value("${SERVICE_NAME:frontend}")
    private String serviceName;


    @RequestMapping("/")
    public String request() {

        System.out.println("Hitting Endpoint");
        long startTime = System.currentTimeMillis();

        RestTemplate restTemplate = new RestTemplate();
        HttpEntity<String> entity = new HttpEntity<>(new HttpHeaders());

        StringBuilder res = new StringBuilder();

        try {
            ResponseEntity<String> resp = restTemplate.exchange(uri, HttpMethod.GET, entity, String.class);
            long timeSpent = System.currentTimeMillis() - startTime;

            res.append(serviceName).append("-").append(timeSpent).append("ms").append("\n");
            res.append(uri).append(" -> ").append(resp.getBody());

        } catch (HttpStatusCodeException e) {
            return ResponseEntity.status(e.getRawStatusCode()).headers(e.getResponseHeaders())
                    .body(e.getResponseBodyAsString()).getStatusCode().toString();
        }

        return res.toString();

    }

    @RequestMapping("/v1")
    public String headersRequest(@RequestHeader HttpHeaders headers) {

        HttpHeaders tracingHeaders = new HttpHeaders();
        extractHeader(headers, tracingHeaders, "x-request-id");
        extractHeader(headers, tracingHeaders, "x-b3-traceid");
        extractHeader(headers, tracingHeaders, "x-b3-spanid");
        extractHeader(headers, tracingHeaders, "x-b3-parentspanid");
        extractHeader(headers, tracingHeaders, "x-b3-sampled");
        extractHeader(headers, tracingHeaders, "x-b3-flags");
        extractHeader(headers, tracingHeaders, "x-ot-span-context");
        extractHeader(headers, tracingHeaders, "x-dev-user");
        extractHeader(headers, tracingHeaders, "fail");

        long startTime = System.currentTimeMillis();

        RestTemplate restTemplate = new RestTemplate();

        StringBuilder res = new StringBuilder();


        try {
            ResponseEntity<String> resp = restTemplate.exchange(uri + "v1", HttpMethod.GET, new HttpEntity<>(tracingHeaders), String.class);
            long timeSpent = System.currentTimeMillis() - startTime;

            res.append(serviceName).append("[v1]").append("-").append(timeSpent).append("ms").append("\n");
            res.append(uri).append(" -> ").append(resp.getBody());

        } catch (HttpStatusCodeException e) {
            return ResponseEntity.status(e.getRawStatusCode()).headers(e.getResponseHeaders())
                    .body(e.getResponseBodyAsString()).getStatusCode().toString();
        }

        return res.toString();

    }


    private static void extractHeader(HttpHeaders headers, HttpHeaders extracted, String key) {
        List<String> vals = headers.get(key);
        if (vals != null && !vals.isEmpty()) {
            extracted.put(key, Arrays.asList(vals.get(0)));
        }
    }


}
