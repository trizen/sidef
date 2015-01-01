function clearContents(element) {
    if (element.value == 'Write your code here...') {
        element.value = "#!/usr/bin/sidef\n\n";
    }
}

$(document).ready(function(){
    $('textarea').autosize();
});

$(document).ready(function(){
    var tabby_opts = {tabString:'    '};
    $('textarea').tabby(tabby_opts);
});
