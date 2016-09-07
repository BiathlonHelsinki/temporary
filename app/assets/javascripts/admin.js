//= require foundation-datetimepicker



function initQuill(id, hidden) {
  if (typeof Quill != 'undefined'){
    // Initialize editor with custom theme and modules
    function copyToInput() {
      $(hidden).html($(id + ' .ql-editor').html());
    }
    function copyFromInput() {
      editor.pasteHTML(0, $(hidden).text());
    }

    var toolbarOptions = [
      ['bold', 'italic', 'underline', 'strike'],        // toggled buttons
      ['blockquote', 'code-block'],

      [{ 'header': 1 }, { 'header': 2 }],               // custom button values
      [{ 'list': 'ordered'}, { 'list': 'bullet' }],
      [{ 'script': 'sub'}, { 'script': 'super' }],      // superscript/subscript
      [{ 'indent': '-1'}, { 'indent': '+1' }],          // outdent/indent
      [{ 'direction': 'rtl' }],                         // text direction
      ['image', 'video', 'link'],
      [{ 'size': ['small', false, 'large', 'huge'] }],  // custom dropdown
      [{ 'header': [1, 2, 3, 4, 5, 6, false] }],

      [{ 'color': [] }, { 'background': [] }],          // dropdown with defaults from theme
      [{ 'font': [] }],
      [{ 'align': [] }],

      ['clean']                                         // remove formatting button
    ];

    var options = {
      modules: {

        toolbar: toolbarOptions
      },
      placeholder: 'Compose an epic...',
      theme: 'snow'
    };

    var editor = new Quill(id, options);  // First matching element will be used

    editor.on('text-change', function(delta, source) {
      console.log('text change');
      copyToInput();
    });
    copyFromInput();

  }


}