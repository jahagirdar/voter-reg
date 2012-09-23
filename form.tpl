

    <html>
    <head>
      <title>[% form.title %]</title>
      [% form.jshead %]
    </head>
    <body>
      [% form.start %]
      <table>
        [% FOREACH field = form.fields %]
        <tr valign="top">
          <td>
            [% field.required
                  ? "<b>$field.label</b>"
                  : field.label
            %]
          </td>
          <td>
            [% IF field.invalid %]
            Missing or invalid entry, please try again.
        <br/>
        [% END %]

        [% field.field %]
      </td>
    </tr>
        [% END %]
        <tr>
          <td colspan="2" align="center">
            [% form.submit %] [% form.reset %]
          </td>
        </tr>
      </table>
      [% form.end %]
    </body>
    </html>
