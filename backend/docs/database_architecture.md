# 数据库架构设计（基于 SRD）

## 1. 表清单

1. `users`：用户信息与账号状态  
2. `orders`：跑腿订单主表  
3. `order_status_logs`：订单状态流转日志  
4. `reviews`：订单评价（二期可直接启用）  
5. `runner_stats`：跑腿员接单统计

## 2. 关系设计

1. `users (1) -> (N) orders.requester_id`  
2. `users (1) -> (N) orders.runner_id`  
3. `orders (1) -> (N) order_status_logs.order_id`  
4. `users (1) -> (N) order_status_logs.operator_id`  
5. `orders (1) -> (0..1) reviews.order_id`（通过唯一约束实现一单一评）  
6. `users (1) -> (N) reviews.reviewer_id`  
7. `users (1) -> (N) reviews.runner_id`  
8. `users (1) -> (0..1) runner_stats.runner_id`

## 3. 索引设计

1. 订单列表：`idx_orders_status_created`  
2. 我的发布：`idx_orders_requester`  
3. 我的接单：`idx_orders_runner`  
4. 过期任务扫描：`idx_orders_status_expected_time`  
5. 评价汇总：`idx_reviews_runner_created`  
6. 评价查询：`idx_reviews_reviewer_created`

## 4. 脚本说明

1. 全量初始化脚本：`sql/week1_schema.sql`  
2. 认证增量脚本：`sql/week3_auth_schema.sql`  
3. 字段注释补丁：`sql/week3_table_comments_patch.sql`  
4. 结构增量补丁（补 reviews 与索引）：`sql/week4_schema_patch.sql`

