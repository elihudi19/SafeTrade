from django.contrib import admin
from . import models

admin.site.site_header = "SafeTrade Admin"
admin.site.site_title = "SafeTrade"
admin.site.index_title = "Usimamizi wa SafeTrade — Mauzo bila kikomo"

admin.site.register(models.Business)
admin.site.register(models.Store)
admin.site.register(models.User)
admin.site.register(models.OTPVerification)
admin.site.register(models.Product)
admin.site.register(models.ShelfStock)
admin.site.register(models.StockTransfer)
admin.site.register(models.StockIntake)
admin.site.register(models.Expense)
admin.site.register(models.DiscrepancyFlag)
admin.site.register(models.Shift)
admin.site.register(models.Receipt)
admin.site.register(models.ReceiptItem)
admin.site.register(models.AuditLog)
admin.site.register(models.MarketplaceListing)
admin.site.register(models.DeliveryOption)
admin.site.register(models.Cart)
admin.site.register(models.CartItem)
admin.site.register(models.Order)
admin.site.register(models.OrderItem)
admin.site.register(models.DeliveryRequest)
admin.site.register(models.Wallet)
admin.site.register(models.WalletTransaction)
admin.site.register(models.FeeTier)
admin.site.register(models.MarketplaceFeeTier)
admin.site.register(models.PredictiveAlert)
