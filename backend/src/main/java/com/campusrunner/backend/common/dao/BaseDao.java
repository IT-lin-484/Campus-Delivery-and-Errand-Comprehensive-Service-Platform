package com.campusrunner.backend.common.dao;

import java.io.Serializable;
import java.lang.reflect.Field;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.TableInfo;
import com.baomidou.mybatisplus.core.metadata.TableInfoHelper;

public interface BaseDao<T> extends BaseMapper<T> {

    default Optional<T> findById(Serializable id) {
        return Optional.ofNullable(selectById(id));
    }

    default T save(T entity) {
        Serializable id = extractId(entity);
        if (id == null) {
            insert(entity);
        } else {
            updateById(entity);
        }
        return entity;
    }

    default void delete(T entity) {
        Serializable id = extractId(entity);
        if (id != null) {
            deleteById(id);
        }
    }

    default List<T> findAllById(Collection<? extends Serializable> ids) {
        if (ids == null || ids.isEmpty()) {
            return List.of();
        }
        return selectBatchIds(ids);
    }

    default long count() {
        return selectCount(new QueryWrapper<>());
    }

    private Serializable extractId(T entity) {
        if (entity == null) {
            return null;
        }

        TableInfo tableInfo = TableInfoHelper.getTableInfo(entity.getClass());
        if (tableInfo == null || tableInfo.getKeyProperty() == null) {
            throw new IllegalStateException("Cannot resolve primary key for " + entity.getClass().getName());
        }

        Field field = findField(entity.getClass(), tableInfo.getKeyProperty());
        try {
            field.setAccessible(true);
            return (Serializable) field.get(entity);
        } catch (IllegalAccessException exception) {
            throw new IllegalStateException("Cannot access primary key field " + field.getName(), exception);
        }
    }

    private Field findField(Class<?> type, String fieldName) {
        Class<?> current = type;
        while (current != null) {
            try {
                return current.getDeclaredField(fieldName);
            } catch (NoSuchFieldException ignored) {
                current = current.getSuperclass();
            }
        }
        throw new IllegalStateException("Cannot find field " + fieldName + " on " + type.getName());
    }
}

