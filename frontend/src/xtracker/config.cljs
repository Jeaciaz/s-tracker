(ns xtracker.config)

(def funnel-total-visuals {:name "Всего"
                           :color "#884EA0"})

(def base-url (str (. js/window.location -protocol) "//" (. js/window.location -hostname) ":8080"))
