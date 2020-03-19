package com.kmarzecki.communicator.util;


import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

public class CollectionUtils {
    @SafeVarargs
    public static <T> Set<T> asSet(T... xs) {
        return Arrays.stream(xs).collect(Collectors.toSet());
    }

    @SafeVarargs
    public static <K, V> Map<K, V> asMap(Function<V, K> keyMapper, V... xs) {
        HashMap<K, V> map = new HashMap<>();
        Arrays.stream(xs)
                .forEach((x) -> map.put(keyMapper.apply(x), x));
        return map;
    }

    public static <T, A> List<A> mapList(Function<T, A> mapper, Collection<T> xs) {
        return xs.stream()
                .map(mapper)
                .collect(Collectors.toList());
    }
}
