#include <gtk/gtk.h>

void AddTextToBuffer(GtkWidget *textview, gchar *text);

void gtk_text_view_append(GtkWidget *textview, GtkWidget *entry)
{
	GtkEntryBuffer *buffer;
	gchar *text;
	buffer = gtk_entry_get_buffer(GTK_ENTRY(entry));
	text = gtk_entry_buffer_get_text(buffer);
	AddTextToBuffer(textview, text);
}

void AddTextToBuffer(GtkWidget *textview, gchar *text)
{
	//Append a string to a textview
	GtkTextBuffer *tbuffer;
	GtkTextIter ei;

	tbuffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(textview));
	gtk_text_buffer_get_end_iter(tbuffer, &ei);
	gtk_text_buffer_insert(tbuffer, &ei, text, -1);

	gtk_text_buffer_get_end_iter(tbuffer, &ei);
	gtk_text_buffer_insert (tbuffer, &ei, "\n", 1);
}