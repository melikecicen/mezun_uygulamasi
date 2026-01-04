-- profiles tablosuna is_notifications_enabled kolonunu ekle
-- Eğer kolon yoksa bu sorguyu Supabase SQL Editor'de çalıştırın

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS is_notifications_enabled BOOLEAN DEFAULT true;

-- Mevcut kullanıcılar için varsayılan değeri true yap
UPDATE profiles
SET is_notifications_enabled = true
WHERE is_notifications_enabled IS NULL;

-- claimed_rewards tablosuna qr_code_text kolonunu ekle
-- QR kod okutma özelliği için gerekli
ALTER TABLE claimed_rewards
ADD COLUMN IF NOT EXISTS qr_code_text TEXT;

