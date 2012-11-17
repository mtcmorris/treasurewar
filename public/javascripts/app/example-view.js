(function() {

  define(['jquery', 'templates'], function($, templates) {
    var ExampleView;
    ExampleView = (function() {

      function ExampleView() {}

      ExampleView.prototype.render = function(element) {
        $(element).append(templates.example({
          name: 'Jade',
          css: 'less'
        }));
        return $(element).append(templates['another-example']({
          name: 'Jade'
        }));
      };

      return ExampleView;

    })();
    return ExampleView;
  });

}).call(this);
