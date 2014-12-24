#!/usr/bin/ruby

# Translation of: http://gtk2-perl.sourceforge.net/doc/gtk2-perl-tut/ch-GettingStarted.html#sec-HelloWorld

Sys.eval('use Gtk2 qw(-init)');
var glib = require('Glib');
var gtk2 = require('Gtk2');

# This is a callback function. We simply say hello to the world, and destroy
# the window object in order to close the program.
func hello(_, window) {
    print "Hello, World\n";
    window->destroy;
}

func delete_event {
    # If you return FALSE in the "delete_event" signal handler,
    # GTK will emit the "destroy" signal. Returning TRUE means
    # you don't want the window to be destroyed.
    # This is useful for popping up 'are you sure you want to quit?'
    # type dialogs.
    print "delete event occurred\n";

    # Change TRUE to FALSE and the main window will be destroyed with
    # a "delete_event".
    return glib.TRUE;
}

# create a new window
var window = 'Gtk2::Window'.to_caller.new('toplevel');

# When the window is given the "delete_event" signal (this is given
# by the window manager, usually by the "close" option, or on the
# titlebar), we ask it to call the delete_event () functio
# as defined above. No data is passed to the callback function.
window->signal_connect(delete_event => delete_event);

# Here we connect the "destroy" event to a signal handler.
# This event occurs when we call Gtk2::Widget::destroy on the window,
# or if we return FALSE in the "delete_event" callback. Perl supports
# anonymous subs, so we can use one of them for one line callbacks.
window->signal_connect(destroy => { gtk2.main_quit });

# Sets the border width of the window.
window->set_border_width(10);

# Creates a new button with a label "Hello World".
var button = "Gtk2::Button".to_caller.new("Hello World");

# When the button receives the "clicked" signal, it will call the function
# hello() with the window reference passed to it.The hello() function is
# defined above.
button->signal_connect(clicked => hello, window);

# This packs the button into the window (a gtk container).
window->add(button);

# The final step is to display this newly created widget.
button->show;

# and the window
window->show;

# All GTK applications must have a call to the main() method. Control ends here
# and waits for an event to occur (like a key press or a mouse event).
gtk2->main;
