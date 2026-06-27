package com.campusrunner.backend.report.dto;

import lombok.Data;

import com.campusrunner.backend.report.enums.ReportTargetType;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 鐢ㄦ埛鎻愪氦涓炬姤璇锋眰銆?
 */
@Data
public class CreateReportRequest {

    @NotBlank(message = "涓炬姤绫诲埆涓嶈兘涓虹┖")
    @Size(max = 60, message = "涓炬姤绫诲埆闀垮害涓嶈兘瓒呰繃 60")
    private String category;

    @NotNull(message = "鐩爣绫诲瀷涓嶈兘涓虹┖")
    private ReportTargetType targetType;

    @NotNull(message = "鐩爣ID涓嶈兘涓虹┖")
    @Min(value = 1, message = "鐩爣ID蹇呴』澶т簬 0")
    private Long targetId;

    @NotBlank(message = "涓炬姤璇存槑涓嶈兘涓虹┖")
    @Size(max = 500, message = "涓炬姤璇存槑闀垮害涓嶈兘瓒呰繃 500")
    private String description;

}
