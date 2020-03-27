package com.kmarzecki.communicator.repository;

import lombok.AllArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.sql.DataSource;

/**
 * Repository configuration
 */
@Configuration
@AllArgsConstructor
@EnableTransactionManagement
public class RepositoryConfiguration {
    private final DataSource dataSource;

    /**
     * @return TransactionManager bean
     */
    @Bean
    public DataSourceTransactionManager transactionManager() {
        return new DataSourceTransactionManager(dataSource);
    }
}
