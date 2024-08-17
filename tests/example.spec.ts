import { test, expect } from '@playwright/test'

test('has title', async ({ page }) => {
  await page.goto('/')
  await page.pause()

  await page
    .locator('#secondary_menu')
    .getByRole('link', { name: 'Démarrer' })
    .click()

  await page.getByText('Je crée ma vidéo solo').click()
  await page.getByRole('button', { name: 'Étape suivante' }).click()
  await page.getByRole('button', { name: 'Étape suivante' }).click()
  await page.getByText('Homme').click()
  await page.getByRole('button', { name: 'Étape suivante' }).click()
  await page.getByPlaceholder("Indiquez l'âge du destinataire").click()
  await page.getByPlaceholder("Indiquez l'âge du destinataire").fill('19')
  await page.getByPlaceholder("Indiquez l'âge du destinataire").press('Tab')
  await page.getByPlaceholder('Indiquez le nom du').click()
  await page.getByPlaceholder('Indiquez le nom du').fill('Samantha')
  await page.getByPlaceholder("Indiquez le nombre d'enfants").click()
  await page.getByPlaceholder("Indiquez le nombre d'enfants").fill('0')
  await page.getByRole('button', { name: 'Étape suivante' }).click()
  await page.locator('#end_date').fill('2024-08-31')
  await page.getByRole('button', { name: 'Étape suivante' }).click()
  await page.getByRole('button', { name: 'Étape suivante' }).click()
  await page.getByPlaceholder('Décrivez votre théme').click()
  await page.getByPlaceholder('Décrivez votre théme').fill('Biengue')
  await page.getByRole('button', { name: 'Étape suivante' }).click()
  await page.getByRole('button', { name: 'Étape suivante' }).click()
  await page.pause()
})
