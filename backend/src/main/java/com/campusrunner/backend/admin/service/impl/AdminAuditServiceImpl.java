package com.campusrunner.backend.admin.service.impl;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campusrunner.backend.admin.dto.AdminAuditLogListResponse;
import com.campusrunner.backend.admin.dto.AdminAuditLogResponse;
import com.campusrunner.backend.admin.entity.AdminAuditLog;
import com.campusrunner.backend.admin.dao.AdminAuditLogDao;

/**
 * 绠＄悊鍛樺璁℃棩蹇楁湇鍔°€? */
@Service
public class AdminAuditServiceImpl implements com.campusrunner.backend.admin.service.AdminAuditService {

    private final AdminAuditLogDao adminAuditLogDao;

    public AdminAuditServiceImpl(AdminAuditLogDao adminAuditLogDao) {
        this.adminAuditLogDao = adminAuditLogDao;
    }

    @Transactional(readOnly = true)
    public AdminAuditLogListResponse listLogs(
            String action,
            String targetType,
            Long operatorId,
            int page,
            int pageSize) {
        Page<AdminAuditLog> result = adminAuditLogDao.selectPage(
                new Page<>(page, pageSize),
                buildQueryWrapper(action, targetType, operatorId));

        List<AdminAuditLogResponse> list = result.getRecords().stream()
                .map(this::toResponse)
                .toList();

        AdminAuditLogListResponse response = new AdminAuditLogListResponse();
        response.setList(list);
        response.setTotal(result.getTotal());
        response.setPage(page);
        response.setPageSize(pageSize);
        return response;
    }

    private LambdaQueryWrapper<AdminAuditLog> buildQueryWrapper(String action, String targetType, Long operatorId) {
        LambdaQueryWrapper<AdminAuditLog> wrapper = Wrappers.lambdaQuery();
        if (action != null && !action.isBlank()) {
            wrapper.eq(AdminAuditLog::getAction, action.trim());
        }
        if (targetType != null && !targetType.isBlank()) {
            wrapper.eq(AdminAuditLog::getTargetType, targetType.trim());
        }
        if (operatorId != null) {
            wrapper.eq(AdminAuditLog::getOperatorId, operatorId);
        }
        wrapper.orderByDesc(AdminAuditLog::getTimestamp);
        return wrapper;
    }

    private AdminAuditLogResponse toResponse(AdminAuditLog log) {
        AdminAuditLogResponse response = new AdminAuditLogResponse();
        response.setId(log.getId());
        response.setOperatorId(log.getOperatorId());
        response.setAction(log.getAction());
        response.setTargetType(log.getTargetType());
        response.setTargetId(log.getTargetId());
        response.setNote(log.getNote());
        response.setIp(log.getIp());
        response.setDeviceId(log.getDeviceId());
        response.setTimestamp(log.getTimestamp());
        return response;
    }
}

