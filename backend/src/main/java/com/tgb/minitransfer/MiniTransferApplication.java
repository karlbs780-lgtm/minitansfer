package com.tgb.minitransfer;

import com.tgb.minitransfer.config.AppProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(AppProperties.class)
public class MiniTransferApplication {

    public static void main(String[] args) {
        SpringApplication.run(MiniTransferApplication.class, args);
    }
}
