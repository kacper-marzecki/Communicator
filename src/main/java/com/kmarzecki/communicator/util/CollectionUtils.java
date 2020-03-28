package com.kmarzecki.communicator.util;


import java.util.Collection;
import java.util.List;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Collection utilities
 */
public class CollectionUtils {

    /**
     * Convert an element to a Set of element
     *
     * @param x element
     * @param <T> type of element x
     * @return a set
     */
    public static <T> Set<T> asSet(T x) {
        return Stream.of(x).collect(Collectors.toSet());
    }

    /**
     * @param mapper function transforming elements of type A  to type B
     * @param xs     Collection A
     * @param <A> type of input element
     * @param <B> type of output element
     * @return List of B
     */
    public static <A, B> List<B> mapList(Function<A, B> mapper, Collection<A> xs) {
        return xs.stream()
                .map(mapper)
                .collect(Collectors.toList());
    }
}
