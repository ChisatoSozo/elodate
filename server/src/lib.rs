extern crate proc_macro;
use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, Expr, ExprArray, FieldValue, ItemStatic, Member};

#[proc_macro]
pub fn generate_user_properties(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as ItemStatic);

    if let Expr::Array(array) = *input.expr {
        let fields = process_array(array, "i16");
        let expanded = quote! {
            struct UserProperties {
                #(#fields),*
            }
        };
        TokenStream::from(expanded)
    } else {
        panic!("Expected an array expression");
    }
}

#[proc_macro]
pub fn generate_preferences(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as ItemStatic);

    if let Expr::Array(array) = *input.expr {
        let fields = process_array(array, "PreferenceRange");
        let expanded = quote! {
            struct Preferences {
                #(#fields),*
            }
        };
        TokenStream::from(expanded)
    } else {
        panic!("Expected an array expression");
    }
}

fn process_array(array: ExprArray, field_type: &str) -> Vec<proc_macro2::TokenStream> {
    let mut fields = Vec::new();

    for expr in array.elems {
        if let Expr::Struct(expr_struct) = expr {
            if let Some(field_value) = get_field_value_by_name(&expr_struct.fields, "name") {
                if let Expr::Lit(syn::ExprLit {
                    lit: syn::Lit::Str(ref lit_str),
                    ..
                }) = field_value.expr
                {
                    let field_name = syn::Ident::new(&lit_str.value(), lit_str.span());
                    let field_type = syn::Ident::new(field_type, proc_macro2::Span::call_site());
                    fields.push(quote! { #field_name: #field_type });
                }
            }
        }
    }

    fields
}

fn get_field_value_by_name<'a>(
    fields: &'a syn::punctuated::Punctuated<FieldValue, syn::token::Comma>,
    name: &str,
) -> Option<&'a FieldValue> {
    for field in fields {
        if let Member::Named(ref ident) = field.member {
            if ident == name {
                return Some(field);
            }
        }
    }
    None
}
