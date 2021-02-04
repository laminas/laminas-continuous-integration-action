const core = require('@actions/core');
const semver = require('semver')

let tagRef = core.getInput('tag-ref');
let tag    = tagRef.split('/').pop();

let major = semver.major(tag);
let minor = major + '.' + semver.minor(tag);

let tags = [
    major,
    minor,
];

core.info(`Original tag: ${tag}`);
core.info(`Tags: ${JSON.stringify(tags)}`);
core.setOutput('original-tag', tag);
core.setOutput('tags', tags.join("\n"));
