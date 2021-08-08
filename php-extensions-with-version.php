#!/usr/bin/env php
<?php

foreach (get_loaded_extensions() as $extension) {
    $version = phpversion($extension);

    printf('%s: %s%s', $extension, $version, PHP_EOL);
}
