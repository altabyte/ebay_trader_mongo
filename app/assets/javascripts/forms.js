$(function () {

    $('.auth-form .svg-textbox > input').focus(
        function () {
            $(this).parent().addClass('svg-textbox-focused');
        }).blur(function () {
            $(this).parent().removeClass('svg-textbox-focused');
        });

    $('.auth-form .svg-textbox').hover(
        function () {
            $(this).addClass('svg-textbox-hover');
        },
        function () {
            $(this).removeClass('svg-textbox-hover');
        });

    $('.auth-form .svg-textbox').click(
        function() {
            $(this).find('input').focus();
        });

    /* This must come AFTER the focus handlers. */
    $('.auth-form #user_email').focus();
});
