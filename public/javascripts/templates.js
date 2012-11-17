define(['vendor/jade-runtime'], function (jade){ var templates = {};

//
// Source file: [/Users/mtcmorris/code/railscamp/treasurewar-ui/assets/javascripts/app/template/another-example.jade]
// Template name: [another-example]
//
templates['another-example'] = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div>And this is coming from another ' + escape((interp = name) == null ? '' : interp) + ' template that is concatenated into a single template file with the others.</div>');
}
return buf.join("");
}

//
// Source file: [/Users/mtcmorris/code/railscamp/treasurewar-ui/assets/javascripts/app/template/example-partial.jade]
// Template name: [example-partial]
//
templates['example-partial'] = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="helper">And this is coming from a Jade partial</div>');
}
return buf.join("");
}

//
// Source file: [/Users/mtcmorris/code/railscamp/treasurewar-ui/assets/javascripts/app/template/example.jade]
// Template name: [example]
//
templates['example'] = function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
with (locals || {}) {
var interp;
buf.push('<div class="template">This is coming from a ' + escape((interp = name) == null ? '' : interp) + ' template</div><div class="helper">And this is coming from a Jade partial</div><div class="styled">And it has all been styled (poorly) using ' + escape((interp = css) == null ? '' : interp) + '</div>');
}
return buf.join("");
}
return templates; });