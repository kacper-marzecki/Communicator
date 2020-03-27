package com.kmarzecki.communicator.util;

import java.time.LocalDateTime;
import java.util.Date;

/**
 * Provider for time data
 */
public interface DateTimeProvider {
    /**
     * @return current date
     */
    Date currentDate();

    /**
     * @return current datetime
     */
    LocalDateTime currentLocalDateTime();
}
