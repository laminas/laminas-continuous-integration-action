#!/usr/bin/env php
<?php

foreach (get_loaded_extensions() as $extension) {
    printf('%s: %s%s', $extension, phpversion($extension), PHP_EOL);
}
