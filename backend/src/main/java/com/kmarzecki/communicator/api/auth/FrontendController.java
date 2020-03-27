package com.kmarzecki.communicator.api.auth;

import org.springframework.http.HttpRequest;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class FrontendController {
    @GetMapping
    public String getFrontend(){
        return "redirect:/index.html";
    }
}
