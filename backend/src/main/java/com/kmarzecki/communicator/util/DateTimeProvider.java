package com.kmarzecki.communicator.util;

import java.time.LocalDateTime;
import java.util.Date;

public interface DateTimeProvider {
    Date getPresentDate();

    LocalDateTime now();
}
