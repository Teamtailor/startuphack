(function () {
    var monster = {
      set: function(name, value, days, path) {
        var date = new Date(),
            expires = '',
            type = typeof(value),
            valueToUse = '';
        path = path || "/";
        if (days) {
          date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
          expires = "; expires=" + date.toGMTString();
        }
        if(type === "object"  && type !== "undefined"){
            if(!("JSON" in window)) throw "Bummer, your browser doesn't support JSON parsing.";
            valueToUse = JSON.stringify({v:value});
        }
        else
          valueToUse = escape(value);

        document.cookie = name + "=" + valueToUse + expires + "; path=" + path + "; domain=" + _trackr_config.domain;
      },
      get: function(name) {
        var nameEQ = name + "=",
            ca = document.cookie.split(';'),
            value = '',
            firstChar = '',
            parsed={};
        for (var i = 0; i < ca.length; i++) {
          var c = ca[i];
          while (c.charAt(0) == ' ') c = c.substring(1, c.length);
          if (c.indexOf(nameEQ) === 0) {
            value = c.substring(nameEQ.length, c.length);
            firstChar = value.substring(0, 1);
            if(firstChar=="{"){
              parsed = JSON.parse(value);
              if("v" in parsed) return parsed.v;
            }
            if(value=="undefined") return undefined;
            return unescape(value);
          }
        }
        return null;
      },
      remove: function(name) {
        this.set(name, "", -1);
      }
    };

    function trackImage(url) {
        var image;
        image = new Image(1, 1);
        image.src = url
    };

    function guidGenerator() {
        var S4 = function() {
            return (((1+Math.random())*0x10000)|0).toString(16).substring(1);
        };
        guid = (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4());
        monster.set('_trackr', guid, 1);
        return guid;
    }

    function getGuid(){
        return monster.get('_trackr') || guidGenerator();
    }

    function logger(){
        trackImage('//startuphack.herokuapp.com/track/'+ _trackr_config.domain + "/" + guid)
        setTimeout(logger,3000);
    };
    var guid = getGuid();
    logger();
})();

