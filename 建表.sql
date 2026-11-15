-- 羽球社共用帳本：ledger 表（唯一一張表）
-- 專案：club-ledger (wshxcwrftxxxtrcobmoh)
-- 只用這張表放帳；登入的社員都能看、記、改、刪所有人的帳。

CREATE TABLE IF NOT EXISTS ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  created_by TEXT NOT NULL DEFAULT '',
  date TEXT NOT NULL,
  court_fee INTEGER NOT NULL DEFAULT 0,
  shuttle_count INTEGER NOT NULL DEFAULT 0,
  shuttle_price INTEGER NOT NULL DEFAULT 0,
  total INTEGER NOT NULL DEFAULT 0,
  paying_count INTEGER NOT NULL DEFAULT 0,
  free_count INTEGER NOT NULL DEFAULT 0,
  -- 每人分攤快照：[{ name, isGuest, free, amount }]
  shares JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE ledger ENABLE ROW LEVEL SECURITY;

-- 只有登入的社員能用；登入者彼此共享同一份帳
CREATE POLICY "社員可見所有人資料"
  ON ledger FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "社員可新增帳目"
  ON ledger FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "社員可修改任何帳目"
  ON ledger FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "社員可刪除任何帳目"
  ON ledger FOR DELETE
  TO authenticated
  USING (true);

-- 更新 updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ledger_updated_at ON ledger;
CREATE TRIGGER ledger_updated_at
  BEFORE UPDATE ON ledger
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- 舊版欄位（若曾建立過）整理掉，確保只有一份 shares 快照
ALTER TABLE ledger DROP COLUMN IF EXISTS members;
ALTER TABLE ledger DROP COLUMN IF EXISTS guests;
ALTER TABLE ledger ADD COLUMN IF NOT EXISTS shares JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE ledger ADD COLUMN IF NOT EXISTS created_by TEXT NOT NULL DEFAULT '';
