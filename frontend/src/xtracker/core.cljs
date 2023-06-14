(ns xtracker.core
  (:require 
    [uix.core.alpha :as uix]
    [uix.dom.alpha :as uix.dom]
    [lambdaisland.fetch :as fetch]

    ["dayjs" :as dayjs]

    [xtracker.settings :as settings]))


;; UTILS 


(defn valid-number? [s]
  (-> s js/parseFloat js/isNaN not))

(defn sum-funnel-values [funnel1 funnel2]
  {:remaining (+ (:remaining funnel1) (:remaining funnel2))
   :limit     (+ (:limit     funnel1) (:limit     funnel2))
   :daily     (+ (:daily     funnel1) (:daily     funnel2))})


;; DATA FETCHING


(defn get-funnels []
  (-> (fetch/get (str settings/base-url "/funnel"))
      (.then #(-> %
                  :body
                  (js->clj {:keywordize-keys true})))))

(defn get-spendings []
  (-> (fetch/get (str settings/base-url "/spending"))
      (.then #(-> %
                  :body
                  (js->clj {:keywordize-keys true})))))

(defn submit-spending [{:keys [amount funnel-id]}]
  (-> (fetch/post (str settings/base-url "/spending") 
                  {:body {:amount amount
                          :timestamp (.now js/Date)
                          :funnel_id funnel-id}
                   :content-type :json})
      (.then (fn [response] 
               (let [status-ok? (<= 200 (:status response) 299)]
                 (when (not status-ok?) 
                   (-> response
                       :body
                       .-detail
                       js->clj
                       js/alert)))))))
  

;; UI


(defn funnels [funnels-list delta]
  "Funnels expect the following keys: [:name :color :remaining :limit :daily]"
  (let [delta-num (if (valid-number? delta) (js/parseFloat delta) 0)]
    [:div.grid.grid-cols-12.gap-2.items-end
      (for [funnel funnels-list]
        [:<> {:key (:name funnel)}
          [:div.col-span-2.text-sm (:name funnel)]
          [:div.col-span-8.text-center.text-lg.relative
            (if (= 0 delta-num)
              [:div.pb-1 (:daily funnel)]
              [:div.pb-1.flex.gap-2.justify-center
                [:span.text-red-600.line-through (:daily funnel)]
                [:span (- (:daily funnel) delta-num)]])
            (for [{:keys [value opacity]} [{:value (- (:remaining funnel) delta-num) :opacity 0.5}
                                           {:value (:remaining funnel) :opacity 0.17}
                                           {:value (:limit funnel) :opacity 0.33}]]
              [:div.absolute.bottom-0.h-1.rounded {:key opacity
                                                   :style {:background-color (:color funnel)
                                                           :opacity opacity
                                                           :width (-> value
                                                                      (/ (:limit funnel))
                                                                      (* 100)
                                                                      (str "%"))}}])]
          [:div.text-end.col-span-2.text-sm (:remaining funnel)]])]))


(defn history [funnels-list spendings]
  "Transaction history. Spendings expects array of maps with keys: [:amount :funnel_id :timestamp]"
  [:div.relative.grow
    [:div.absolute.inset-0.overflow-y-auto
      (for [spending spendings]
        (let [emoji (:emoji (some #(if (= (:funnel_id spending) (:id %)) %) funnels-list))
              datetime (-> spending
                           :timestamp
                           (dayjs)
                           (.format "HH:mm; DD.MM.YY"))]
          [:div.flex.gap-2.py-4.border-b.border-slate-200 {:key (:timestamp spending)}
            [:div emoji]
            [:div (:amount spending)]
            [:div.ms-auto datetime]]))]])
    

(defn app []
  (let [delta* (uix/state "")
        funnels-list* (uix/state {:status :pending
                                  :data nil})
        spendings-list* (uix/state :pending)
        pending-funnels? (= :pending (:status @funnels-list*))
        refresh! (fn []
                   (reset! delta* "")
                   (reset! spendings-list* :pending)
                   (-> (get-funnels)
                       (.then #(reset! funnels-list* {:status :ok 
                                                      :data %})))
                   (-> (get-spendings)
                       (.then #(reset! spendings-list* %))))]
    (uix/effect!
      refresh!
      [])
    [:div.px-4.py-8.flex.flex-col.h-screen
      [:h1.text-4xl "XTracker"]
      [:div.mt-6
        (if (= (:data @funnels-list*) nil) 
          [:span "loading..."]
          (let [funnel-total (into settings/funnel-total-visuals
                                   (reduce sum-funnel-values 
                                           {:limit 0
                                            :remaining 0
                                            :daily 0} 
                                           (:data @funnels-list*)))]
                                    
            [:div 
             (funnels (cons funnel-total (:data @funnels-list*)) @delta*) 
             [:input.mt-4.py-2.px-1.rounded.border.border-slate-300.w-full.text-2xl 
               {:input-mode "numeric" 
                :value @delta* 
                :on-change #(reset! delta* (.. % -target -value))
                :placeholder "20.5"}]
             [:div.grid.grid-cols-2.mt-4
               (for [funnel (:data @funnels-list*)]
                 [:button.py-2.active:brightness-75 {:key (:id funnel)
                                                     :style {:background-color (:color funnel)}
                                                     :class (filter
                                                              #(not= nil %)
                                                              [(when (not (valid-number? @delta*)) "pointer-events-none contrast-75")
                                                               (when pending-funnels? "animate-pulse")])
                                                             
                                                     :on-click (fn []
                                                                 (swap! funnels-list* assoc :status :pending)
                                                                 (-> (submit-spending {:amount @delta* :funnel-id (:id funnel)})
                                                                   (.then refresh!)))}
                               (:emoji funnel)])]]))]
      (if (= @spendings-list* :pending)
        [:span "loading..."]
        (history (:data @funnels-list*) @spendings-list*))]))


;; SHADOW-CLJS HOOKS


(defn start []
  (prn "start") 
  (uix.dom/render [app] (.getElementById js/document "app")))

(defn ^:export init []
  (start))

(defn stop []
  (prn "stop"))

(defn reload []
  (prn "reload"))
