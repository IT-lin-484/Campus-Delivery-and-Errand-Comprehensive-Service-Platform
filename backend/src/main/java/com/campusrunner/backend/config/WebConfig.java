package com.campusrunner.backend.config;

import java.nio.file.Paths;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web MVC 配置类
 * 主要功能：
 * 1. 配置 CORS（跨域资源共享），允许前端跨域访问后端 API
 * 2. 配置文件上传目录的静态资源映射，使上传的文件可以通过 URL 直接访问
 */
@Configuration // 标记为 Spring 配置类，Spring 启动时会自动加载
public class WebConfig implements WebMvcConfigurer {

    // 允许跨域访问的前端域名列表，默认值 http://localhost:5173（Vite/React 开发服务器地址）
    @Value("${app.cors.allowed-origins:http://localhost:5173}")
    private String[] allowedOrigins;

    // 文件上传的存储目录，默认值为项目根目录下的 uploads 文件夹
    @Value("${app.upload.base-dir:./uploads}")
    private String uploadBaseDir;

    /**
     * 配置 CORS 跨域映射规则
     * 解决前后端分离开发时，浏览器同源策略导致的跨域请求限制
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        // 路径 /api/** 下的所有接口：允许完整的增删改查操作
        registry.addMapping("/api/**")
                .allowedOrigins(allowedOrigins)       // 允许哪些域名跨域访问
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS") // 允许的 HTTP 方法
                .allowCredentials(true)               // 允许携带 Cookie/认证信息
                .maxAge(3600);                        // 预检请求(OPTIONS)缓存时间，单位秒

        // 路径 /uploads/** 下的静态文件：仅允许 GET 请求
        registry.addMapping("/uploads/**")
                .allowedOrigins(allowedOrigins)       // 允许跨域访问文件的前端域名
                .allowedMethods("GET")                // 只允许读取，不允许修改
                .allowCredentials(true)
                .maxAge(3600);
    }

    /**
     * 配置静态资源处理器
     * 将本地文件系统的上传目录映射为 HTTP 访问路径 /uploads/**
     * 例如：本地文件 ./uploads/avatar.png 可通过 http://域名/uploads/avatar.png 访问
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 将相对路径转为绝对路径，并进行标准化处理（消除 ../ 等冗余路径）
        String uploadLocation = Paths.get(uploadBaseDir)
                .toAbsolutePath()    // 转为绝对路径
                .normalize()         // 标准化路径（去除多余斜杠、上级目录引用等）
                .toUri()             // 转为 URI 格式字符串
                .toString();

        // 确保路径以 / 结尾，Spring 要求资源位置必须是目录形式
        if (!uploadLocation.endsWith("/")) {
            uploadLocation = uploadLocation + "/";
        }

        // 注册资源映射：将 /uploads/** 的 HTTP 请求映射到本地上传目录
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(uploadLocation);
    }
}
