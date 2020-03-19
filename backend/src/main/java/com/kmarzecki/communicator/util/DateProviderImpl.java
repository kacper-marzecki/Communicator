package com.kmarzecki.communicator.util;

import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Date;

@Component
class DateProviderImpl implements DateTimeProvider {
    @Override
    public Date getPresentDate() {
        return new Date();
    }

    @Override
    public LocalDateTime now() {
        return LocalDateTime.now();
    }
}
