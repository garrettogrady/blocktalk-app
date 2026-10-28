export type PostStatus = "live" | "under_review" | "removed";

export interface Neighborhood {
  id: string;
  name: string;
  short_code: string;
  borough: string;
}

export interface User {
  id: string;
  username: string;
  user_number: number;
  home_neighborhood_id: string | null;
  home_changed_at: string | null;
  is_seed: boolean;
  created_at: string;
  neighborhood?: Neighborhood;
}

export interface Post {
  id: string;
  user_id: string;
  neighborhood_id: string;
  text: string;
  image_url: string | null;
  pin_id: string | null;
  is_daily_prompt: boolean;
  daily_prompt_id: string | null;
  score: number;
  reply_count: number;
  report_count: number;
  status: PostStatus;
  created_at: string;
  author?: { username: string; user_number: number };
  neighborhood?: { name: string };
}

export interface Report {
  id: string;
  reporter_id: string;
  post_id: string;
  reason: string;
  free_text: string | null;
  created_at: string;
  reporter?: { username: string };
}

export interface ModerationPost extends Post {
  reports: Report[];
}

export interface Feedback {
  id: string;
  user_id: string;
  body: string;
  created_at: string;
  user?: { username: string; user_number: number };
}

export interface ModerationAction {
  id: string;
  post_id: string;
  user_id: string | null;
  action: "remove" | "restore" | "uphold" | "overturn";
  reason: string | null;
  admin_note: string | null;
  created_at: string;
}

export interface Strike {
  id: string;
  user_id: string;
  post_id: string;
  moderation_action_id: string;
  created_at: string;
}

export type AppealStatus = "pending" | "accepted" | "rejected";

export interface Appeal {
  id: string;
  user_id: string;
  post_id: string;
  appeal_text: string;
  status: AppealStatus;
  created_at: string;
  user?: { username: string; user_number: number };
  post?: Post;
}

/** One quiz submission (Supabase/00034). Answers are keyed by question id. */
export interface SurveyAnswer { choice?: string; text?: string }
export interface SurveyResponse {
  id: string;
  created_at: string;
  src: "p1" | "p2" | "p3" | "direct";
  quiz: "regular" | "purist";
  answers: Record<string, SurveyAnswer>;
  score: number;
  tier: "CITY SLICKER" | "BLOCKTALKER" | "TRANSPLANT" | "TOURIST";
  email: string;
  neighborhood: string;
  phone: string | null;
  sms_consent: boolean;
  contacted: boolean;
  user_agent: string | null;
}

/** One question row from survey_questions, used to label answers in order. */
export interface SurveyQuestion { quiz: "regular" | "purist"; q: string; ord: number; prompt: string }

/** One take from a rant tab (who / ai / influencers). */
export interface RantResponse {
  id: string;
  created_at: string;
  tab: "who" | "ai" | "influencers";
  body: string;
  email: string | null;
  contacted: boolean;
  user_agent: string | null;
}
