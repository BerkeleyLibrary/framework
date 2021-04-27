// Hacking Rails flash alerts -- see application_helper.rb
// for where/how server-side alerts are rendered
class FlashAlerts {
    alerts() {
        return document.querySelector('div.alerts');
    }

    clear() {
        let alerts = this.alerts();
        if (alerts) {
            let child;
            while((child = parent.firstChild)) {
                child.remove()
            }
        }
    }

    success(msg) {
        this.addAlert(msg, 'success')
    }

    danger(msg) {
        this.addAlert(msg, 'danger')
    }

    addAlert(msg, lvl) {
        let alerts = this.alerts()
        if (!alerts) {
            console.log(`Alerts container not present; can't add alert message "${msg}"`);
            return
        }
        let alert = document.createElement('div');
        alert.className = `alert alert-${lvl}`
        return alerts.appendChild(alert)
    }
}

const flashAlerts = new FlashAlerts()
