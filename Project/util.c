#include <gtk/gtk.h>
#include <glib.h>

void AddTextToBuffer(GtkWidget *textview, gchar *text);

void gtk_text_view_append(GtkWidget *textview, GtkWidget *entry)
{
	/* Append text from a Gtk Entry to a Gtk Text View */
	// Initialize the variables
	GtkEntryBuffer *buffer;
	gchar *text;
	
	// Get the text from the entry
	buffer = gtk_entry_get_buffer(GTK_ENTRY(entry));
	text = gtk_entry_buffer_get_text(buffer);
	// Add it to the Text View
	AddTextToBuffer(textview, text);
}

void AddTextToBuffer(GtkWidget *textview, gchar *text)
{
	/* Appent text to a Gtk Text View */
	// If there is no text to add, return
	if(text == NULL)
		return;
	// Initialize the variables
	GtkTextBuffer *tbuffer;
	GtkTextIter ei;
	
	// Get the text buffer and the new text and merge them
	tbuffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(textview));
	gtk_text_buffer_get_end_iter(tbuffer, &ei);
	gtk_text_buffer_insert(tbuffer, &ei, text, -1);

	// Append a newline to the Text View
	gtk_text_buffer_get_end_iter(tbuffer, &ei);
	gtk_text_buffer_insert (tbuffer, &ei, "\n", 1);
}
